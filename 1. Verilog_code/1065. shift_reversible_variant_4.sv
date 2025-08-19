//SystemVerilog
module shift_reversible #(parameter WIDTH=8) (
    input  clk,
    input  rst_n,
    input  reverse,
    input  [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

// Stage 1: Input buffering
reg [WIDTH-1:0] din_stage1;

// Stage 2: Bit extraction for shift
reg [WIDTH-1:0] din_stage2;
reg             reverse_stage2;
reg             lsb_stage2;
reg             msb_stage2;

// Stage 3: Shift operation
reg [WIDTH-1:0] shift_result_stage3;

// Stage 4: Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_stage1 <= {WIDTH{1'b0}};
    end else begin
        din_stage1 <= din;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_stage2      <= {WIDTH{1'b0}};
        reverse_stage2  <= 1'b0;
        lsb_stage2      <= 1'b0;
        msb_stage2      <= 1'b0;
    end else begin
        din_stage2      <= din_stage1;
        reverse_stage2  <= reverse;
        lsb_stage2      <= din_stage1[0];
        msb_stage2      <= din_stage1[WIDTH-1];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_result_stage3 <= {WIDTH{1'b0}};
    end else begin
        if (reverse_stage2)
            shift_result_stage3 <= {lsb_stage2, din_stage2[WIDTH-1:1]};
        else
            shift_result_stage3 <= {din_stage2[WIDTH-2:0], msb_stage2};
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= {WIDTH{1'b0}};
    end else begin
        dout <= shift_result_stage3;
    end
end

endmodule