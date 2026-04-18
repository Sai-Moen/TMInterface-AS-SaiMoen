/*

smn_utils | Assert | v3.0.0

Features:
- Unreachable
- Panic
- Assert

*/


funcdef void OnUnreachable();

void Unreachable()
{
	OnUnreachable@ unreachable;
	// This function only gets called if something went wrong.
	unreachable();
}

funcdef void OnPanic(const string &in message);

void IgnoreError(const string &in message) {}

void LogError(const string &in message)
{
	log(message, Severity::Error);
}

void PrintError(const string &in message)
{
	print(message, Severity::Error);
}

void Panic(const string &in message, const OnPanic@ callback)
{
	callback(message);
	Unreachable();
}

void Panic()
{
	Panic("", IgnoreError);
}

void PanicLog(const string &in message)
{
	Panic(message, LogError);
}

void PanicPrint(const string &in message)
{
	Panic(message, PrintError);
}

void Assert(const bool condition, const string &in message, const OnPanic@ callback)
{
	if (condition)
		return;

	Panic(message, callback);
}

void Assert(const bool condition)
{
	Assert(condition, "", IgnoreError);
}

void AssertLog(const bool condition, const string &in message)
{
	Assert(condition, message, LogError);
}

void AssertPrint(const bool condition, const string &in message)
{
	Assert(condition, message, PrintError);
}
