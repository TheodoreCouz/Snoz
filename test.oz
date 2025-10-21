declare
{OS.srand {OS.time}}          % seed with current time
N = {OS.rand} mod 100         % random integer in [0, 99]
{Browse N}