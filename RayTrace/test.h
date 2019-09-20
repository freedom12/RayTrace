#pragma once
#include <iostream>
using namespace std;

class MyClass
{
public:
	MyClass();
	~MyClass();

	MyClass(const MyClass& c);
	MyClass& operator=(const MyClass& rhs);

	MyClass(MyClass&& c) noexcept;
	MyClass& operator=(MyClass&& rhs) noexcept;
private:

};

inline MyClass::MyClass()
{
	cout << "构造函数" << endl;
}

inline MyClass::~MyClass()
{
	cout << "析构析构" << endl;
}

inline MyClass::MyClass(const MyClass& c)
{
	cout << "拷贝构造函数" << endl;
}

inline MyClass& MyClass::operator=(const MyClass& rhs)
{
	cout << "拷贝赋值运算" << endl;
	auto myClass(rhs);
	return myClass;
}

inline MyClass::MyClass(MyClass&& c) noexcept
{
	cout << "移动构造函数" << endl;
}


inline MyClass& MyClass::operator=(MyClass&& rhs) noexcept
{
	cout << "移动赋值运算" << endl;
	return rhs;
}
