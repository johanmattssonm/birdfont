#include <iostream>
#include <fstream>

using namespace std;

int main(int argc, char**argv)
{
	if (argc != 3) {
		cout<<"usage ./comp in out"<<endl;
		return 3;
	}

	ifstream in(argv[1], ios::in|ios::binary|ios::ate);
	if (in.is_open())
	{
		ifstream::pos_type size = in.tellg();
		char *buf = new char[size];

		in.seekg(0, ios::beg);
		in.read(buf, size);
		in.close();

		ofstream out(argv[2]);
		if (out.is_open())
		{
			out.write(buf, size);
			out.close();
		}
		else
		{
			return 2;
		}
		delete[] buf;
	}
	else
	{
		return 1;
	}
	return 0;
}
