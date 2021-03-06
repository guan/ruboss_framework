/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
package org.ruboss.services {
  import mx.collections.ArrayCollection;
  import mx.controls.Alert;
  import mx.managers.CursorManager;
  import mx.rpc.IResponder;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossModelsController;

  public class ServiceResponder implements IResponder {

    private var handler:Function;
    private var service:IServiceProvider;
    private var controller:RubossModelsController;
    private var afterCallback:Object;
    
    private var checkOrder:Boolean;
    private var useLazyMode:Boolean;

    
    public function ServiceResponder(handler:Function, service:IServiceProvider, 
      controller:RubossModelsController, checkOrder:Boolean, useLazyMode:Boolean, 
      afterCallback:Object = null) {
      this.handler = handler;
      this.service = service;
      this.controller = controller;
      this.checkOrder = checkOrder;
      this.useLazyMode = useLazyMode;
      this.afterCallback = afterCallback;
    }
    
    private function checkResultOrder(fqn:String, event:Object):Boolean {
      // if we didn't get an fqn from the service provider or we explicitly don't need to do
      // checking then just return true
      if (!fqn || !checkOrder) return true;
      
      if (!controller.state.standalone[fqn] && !controller.state.fetched[fqn]) {
        var dependencies:Array = (useLazyMode) ? controller.state.lazy[fqn] : controller.state.eager[fqn];
        for each (var dependency:String in dependencies) {
          // if we are still missing some dependencies queue this response 
          // for later 
          if (!controller.state.fetched[dependency]) {
            Ruboss.log.debug("missing dependency: " + dependency + " of: " + fqn + 
              " queuing this response until the dependency is received.");
            (Ruboss.models.state.queue[dependency] as Array).push({"target":this, 
              "event":event});
            return false;
          }
        }
      }
      
      // OK, so looks like we have all the dependencies, mark this model 
      // as fetched
      controller.state.fetched[fqn] = true;
      return true;
    }
    
    private function invokeAfterCallback(result:Object):void {
      if (afterCallback is IResponder) {
        IResponder(afterCallback).result(result);
      } else if (afterCallback is Function) {
        (afterCallback as Function)(result);
      }
    }

    public function result(event:Object):void {
      CursorManager.removeBusyCursor();    
      if (handler != null) {
        if (!service.error(event.result)) {
          var fqn:String = service.peek(event.result);
          if (checkResultOrder(fqn, event)) {
            Ruboss.log.debug("handling response for: " + fqn);
            var checkedResult:Object = service.unmarshall(event.result);
            handler.call(controller, checkedResult);
            for each (var dependant:Object in controller.state.queue[fqn]) {
              var target:Object = dependant["target"];
              var targetEvent:Object = dependant["event"];
              IResponder(target).result(targetEvent);
            }
            // OK so we notified all the dependants, need to clean up
            controller.state.queue[fqn] = new Array;
            // and fire user's callback responder here
            if (afterCallback != null) {
              invokeAfterCallback(checkedResult);
            }     
          }
          
          //reset the standalone flag
          delete controller.state.standalone[fqn];
        }
      }
    }
    
    public function fault(error:Object):void {
      CursorManager.removeBusyCursor();
      Alert.show("Error", "An error has occured while invoking service provider with id: " + service.id + 
        ". Enabled debugging and check the console for details.");
      Ruboss.log.error(error.toString());
    }
  }
}