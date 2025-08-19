//SystemVerilog
module power_efficient_shifter(
    input clk,
    input en,
    input [7:0] data_in,
    input [2:0] shift,
    output [7:0] data_out
);
    // Internal connections
    wire [7:0] stage0_out, stage1_out;
    
    // Power gating signals
    wire active_stage0, active_stage1, active_stage2;
    
    // Enable signals for power efficiency
    assign active_stage0 = en & |shift;
    assign active_stage1 = en & |shift[2:1];
    assign active_stage2 = en & shift[2];
    
    // Stage 0: 1-bit shifter
    shift_stage0 u_shift_stage0 (
        .clk(clk),
        .en(active_stage0),
        .data_in(data_in),
        .shift_bit(shift[0]),
        .data_out(stage0_out)
    );
    
    // Stage 1: 2-bit shifter
    shift_stage1 u_shift_stage1 (
        .clk(clk),
        .en(active_stage1),
        .data_in(stage0_out),
        .shift_bit(shift[1]),
        .data_out(stage1_out)
    );
    
    // Stage 2: 4-bit shifter
    shift_stage2 u_shift_stage2 (
        .clk(clk),
        .en(active_stage2),
        .data_in(stage1_out),
        .shift_bit(shift[2]),
        .data_out(data_out)
    );
endmodule

// Stage 0: 1-bit shift module
module shift_stage0(
    input clk,
    input en,
    input [7:0] data_in,
    input shift_bit,
    output reg [7:0] data_out
);
    always @(posedge clk) begin
        if (en) begin
            if (shift_bit)
                data_out <= {data_in[6:0], 1'b0};
            else
                data_out <= data_in;
        end else begin
            data_out <= data_in;
        end
    end
endmodule

// Stage 1: 2-bit shift module
module shift_stage1(
    input clk,
    input en,
    input [7:0] data_in,
    input shift_bit,
    output reg [7:0] data_out
);
    always @(posedge clk) begin
        if (en) begin
            if (shift_bit)
                data_out <= {data_in[5:0], 2'b0};
            else
                data_out <= data_in;
        end else begin
            data_out <= data_in;
        end
    end
endmodule

// Stage 2: 4-bit shift module
module shift_stage2(
    input clk,
    input en,
    input [7:0] data_in,
    input shift_bit,
    output reg [7:0] data_out
);
    always @(posedge clk) begin
        if (en) begin
            if (shift_bit)
                data_out <= {data_in[3:0], 4'b0};
            else
                data_out <= data_in;
        end else begin
            data_out <= data_in;
        end
    end
endmodule