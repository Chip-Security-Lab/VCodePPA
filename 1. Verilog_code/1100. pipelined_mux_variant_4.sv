//SystemVerilog
module pipelined_mux (
    input  wire        clk,               // System clock
    input  wire [1:0]  address,           // Selection address
    input  wire [15:0] data_0, 
    input  wire [15:0] data_1, 
    input  wire [15:0] data_2, 
    input  wire [15:0] data_3,            // Data inputs
    output reg  [15:0] result             // Registered result
);

    wire [15:0] mux_selected_data;

    // Combinational selection logic in a separate module
    mux4to1_16bit u_mux4to1_16bit (
        .sel(address),
        .in0(data_0),
        .in1(data_1),
        .in2(data_2),
        .in3(data_3),
        .out(mux_selected_data)
    );

    // Synchronous pipeline register
    always @(posedge clk) begin
        result <= mux_selected_data;
    end

endmodule

// 4-to-1 16-bit combinational multiplexer module
module mux4to1_16bit (
    input  wire [1:0]  sel,
    input  wire [15:0] in0,
    input  wire [15:0] in1,
    input  wire [15:0] in2,
    input  wire [15:0] in3,
    output reg  [15:0] out
);
    always @(*) begin
        if (sel == 2'b00) begin
            out = in0;
        end else if (sel == 2'b01) begin
            out = in1;
        end else if (sel == 2'b10) begin
            out = in2;
        end else begin
            out = in3;
        end
    end
endmodule