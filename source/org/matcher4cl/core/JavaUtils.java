package org.matcher4cl.core;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import com.redhat.ceylon.compiler.java.runtime.model.TypeDescriptor;

public class JavaUtils {

//	public static Set<ceylon.language.String> getFieldNames(Object obj) {
//		Set<ceylon.language.String> fieldNames = new HashSet<ceylon.language.String>();
//		addFieldNames(obj.getClass(), fieldNames);
//		return fieldNames;
//	}
//	
//	private static void addFieldNames(Class obj, Set<ceylon.language.String> fieldNames) {
//		
//		for(Field field: obj.getDeclaredFields()) {
//			if(field.getType() == TypeDescriptor.class) {
//				continue;
//			}
//			String fieldName = field.getName();
//			ceylon.language.String s = ceylon.language.String.instance(fieldName);
//			fieldNames.add(s);
//		}
//		
//		Class superClass = obj.getSuperclass();
//		if(superClass != null)
//			addFieldNames(superClass, fieldNames);
//		
//	}
//
//	public static Object extractField(Object obj, String fieldName) throws NoSuchFieldException, SecurityException, IllegalArgumentException, 
//		IllegalAccessException, NoSuchMethodException, InvocationTargetException {
//		
//		/* public final java.lang.String org.matcher4cl.test.AAA.getName(), 
//		 * public final void org.matcher4cl.test.AAA.setName(java.lang.String), 
//		 * public com.redhat.ceylon.compiler.java.runtime.model.TypeDescriptor 
//		 * org.matcher4cl.test.AAA.$getType(), 
//		 * public final long org.matcher4cl.test.AAA.getAge(), 
//		 * public final void org.matcher4cl.test.AAA.setAge(long)
//		 * ]*/
//
//		System.out.println("Methods: " + Arrays.toString(obj.getClass().getDeclaredMethods()));
//		System.out.println("Fields: "  + Arrays.toString(obj.getClass().getDeclaredFields()));
//		System.out.println("Fields: "  + Arrays.toString(obj.getClass().getFields()));
//		
//		
//		Field field = obj.getClass().getDeclaredField(fieldName);
//		
//		String methodName = (field.getType() == Boolean.class ? "is" : "get") +
//				fieldName.substring(0, 1).toUpperCase() +
//				fieldName.substring(1, fieldName.length());
//		System.out.println(" Method name: " + methodName);
//		
//		Method method = obj.getClass().getMethod(methodName); 
//		Object fieldObj = method.invoke(obj);
//		
////		Object fieldObj = field.get(obj);
//		return fieldObj;
//	}
	
	
	
	
}
