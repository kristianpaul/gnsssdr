module fdce2(
	output [1:0] q,
	input c,
	input ce,
	input [1:0] d,
	input clr
);

FDCE FDCE_dof0 (
    .Q(q[0]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[0]) // Data input
);

FDCE FDCE_dof1 (
    .Q(q[1]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[1]) // Data input
);
endmodule
