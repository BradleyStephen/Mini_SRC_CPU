module pc_register (
    input wire clk,
    input wire reset,
    input wire load,
    input wire enable_out,
    input wire [31:0] d,
    output wire [31:0] q,
    output wire [31:0] bus_out
);
    register pc (
        .clk(clk),
        .reset(reset),
        .load(load),
        .enable_out(enable_out),
        .d(d),
        .q(q),
        .bus_out(bus_out)
    );
endmodule

module ir_register (
    input wire clk,
    input wire reset,
    input wire load,
    input wire enable_out,
    input wire [31:0] d,
    output wire [31:0] q,
    output wire [31:0] bus_out
);
    register ir (
        .clk(clk),
        .reset(reset),
        .load(load),
        .enable_out(enable_out),
        .d(d),
        .q(q),
        .bus_out(bus_out)
    );
endmodule
