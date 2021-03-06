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
package org.ruboss.models {
  import mx.collections.ArrayCollection;

  public class ModelsCollection extends ArrayCollection {
    public function ModelsCollection(source:Array = null) {
      super(source);
    }

    [Bindable("collectionChange")]
    public function withPropertyValue(propertyName:String, propertyValue:Object):Object {
      var index:int = indexOfPropertyValue(propertyName, propertyValue);
      return (index == -1) ? null : getItemAt(index);
    }
    
    [Bindable("collectionChange")]
    public function withId(id:int):Object {
      var index:int = indexOfId(id);
      return (index == -1) ? null : getItemAt(index);
    }
    
    public function hasItem(object:Object):Boolean {
      return withId(object["id"]) != null;
    }
    
    [Bindable("collectionChange")]
    public function getItem(object:Object):Object {
      return withId(object["id"]);
    }
        
    public function setItem(object:Object):void {
      setItemAt(object, indexOfId(object["id"]));
    }
    
    public function removeItem(object:Object):void {
      removeItemAt(indexOfId(object["id"]));
    }

    public function indexOfPropertyValue(propertyName:String, propertyValue:Object):int {
      for (var i:int = 0; i < length; i++) {
        if (getItemAt(i)[propertyName] == propertyValue) return i;
      }
      return -1;
    }
    
    public function indexOfId(id:int):int {
      return indexOfPropertyValue("id", id);
    }
  }
}