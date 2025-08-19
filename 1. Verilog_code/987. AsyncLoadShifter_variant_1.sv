//SystemVerilog
// Top-level module: Hierarchical Async Load Shifter with Pipelined Critical Path
module AsyncLoadShifter #(parameter WIDTH=8) (
    input clk,
    input async_load,
    input [WIDTH-1:0] load_data,
    output [WIDTH-1:0] data_reg
);

    wire [WIDTH-1:0] shifter_stage1_out;
    wire [WIDTH-1:0] mux_stage1_out;
    reg  [WIDTH-1:0] mux_stage2_reg;
    reg  [WIDTH-1:0] shifter_stage2_reg;
    reg              async_load_stage1;

    // Pipeline Register: Stage 1 - Register async_load and load_data
    always @(posedge clk) begin
        mux_stage2_reg      <= mux_stage1_out;
        async_load_stage1   <= async_load;
    end

    // Submodule: Asynchronous Load Mux (combinational, pipelined at output)
    AsyncLoadMux #(.WIDTH(WIDTH)) u_async_load_mux (
        .load_data(load_data),
        .shifted_data(shifter_stage1_out),
        .async_load(async_load),
        .mux_out(mux_stage1_out)
    );

    // Pipeline Register: Stage 2 - Register mux output
    always @(posedge clk) begin
        shifter_stage2_reg <= mux_stage2_reg;
    end

    // Submodule: Shift Register (shift operation only, pipelined)
    ShiftRegister #(.WIDTH(WIDTH)) u_shift_register (
        .clk(clk),
        .d(shifter_stage2_reg),
        .q(shifter_stage1_out)
    );

    // Output assignment - align with pipeline delay
    assign data_reg = shifter_stage1_out;

endmodule

// Submodule: Asynchronous Load Mux
module AsyncLoadMux #(parameter WIDTH=8) (
    input  [WIDTH-1:0] load_data,
    input  [WIDTH-1:0] shifted_data,
    input              async_load,
    output [WIDTH-1:0] mux_out
);
    assign mux_out = async_load ? load_data : {shifted_data[WIDTH-2:0], 1'b0};
endmodule

// Submodule: Shift Register with synchronous load
module ShiftRegister #(parameter WIDTH=8) (
    input              clk,
    input  [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule