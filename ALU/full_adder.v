module full_adder(
    input  wire a,     // 1-bit input A
    input  wire b,     // 1-bit input B
    input  wire cin,   // Carry In
    output wire sum,   // Sum Output
    output wire cout   // Carry Out
);

    // Full adder logic
    assign {cout, sum} = a + b + cin;

endmodule
