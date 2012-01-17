module fdce16(
	output [15:0] q,
	input c,
	input ce,
	input [15:0] d,
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
FDCE FDCE_dof2 (
    .Q(q[2]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[2]) // Data input
);
FDCE FDCE_dof3 (
    .Q(q[3]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[3]) // Data input
);
FDCE FDCE_dof4 (
    .Q(q[4]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[4]) // Data input
);
FDCE FDCE_dof5 (
    .Q(q[5]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[5]) // Data input
);
FDCE FDCE_dof6 (
    .Q(q[6]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[6]) // Data input
);
FDCE FDCE_dof7 (
    .Q(q[7]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[7]) // Data input
);
FDCE FDCE_dof8 (
    .Q(q[8]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[8]) // Data input
);
FDCE FDCE_dof9 (
    .Q(q[9]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[9]) // Data input
);
FDCE FDCE_dof10 (
    .Q(q[10]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[10]) // Data input
);
FDCE FDCE_dof11 (
    .Q(q[11]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[11]) // Data input
);
FDCE FDCE_dof12 (
    .Q(q[12]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[12]) // Data input
);
FDCE FDCE_dof13 (
    .Q(q[13]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[13]) // Data input
);
FDCE FDCE_dof14 (
    .Q(q[14]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[14]) // Data input
);
FDCE FDCE_dof15 (
    .Q(q[15]), // Data output
    .C(c), // Clock input
    .CE(ce), // Clock enable input
    .CLR(clr), // Asynchronous clear input
    .D(d[15]) // Data input
);
endmodule
