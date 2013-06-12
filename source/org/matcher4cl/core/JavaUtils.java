package org.matcher4cl.core;

import java.lang.reflect.Field;
import java.util.HashSet;
import java.util.Set;

public class JavaUtils {

	public static Set<ceylon.language.String> getFieldNames(Object obj) {
		Set<ceylon.language.String> fieldNames = new HashSet<ceylon.language.String>();
		addFieldNames(obj.getClass(), fieldNames);
		return fieldNames;
	}
	
	private static void addFieldNames(Class obj, Set<ceylon.language.String> fieldNames) {
		
		
		for(Field field: obj.getDeclaredFields()) {
			String fieldName = field.getName();
			ceylon.language.String s = ceylon.language.String.instance(fieldName);
			fieldNames.add(s);
		}
		
		Class superClass = obj.getSuperclass();
		if(superClass != null)
			addFieldNames(superClass, fieldNames);
		
	}
	
}
