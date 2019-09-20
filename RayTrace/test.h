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
	cout << "���캯��" << endl;
}

inline MyClass::~MyClass()
{
	cout << "��������" << endl;
}

inline MyClass::MyClass(const MyClass& c)
{
	cout << "�������캯��" << endl;
}

inline MyClass& MyClass::operator=(const MyClass& rhs)
{
	cout << "������ֵ����" << endl;
	auto myClass(rhs);
	return myClass;
}

inline MyClass::MyClass(MyClass&& c) noexcept
{
	cout << "�ƶ����캯��" << endl;
}


inline MyClass& MyClass::operator=(MyClass&& rhs) noexcept
{
	cout << "�ƶ���ֵ����" << endl;
	return rhs;
}
