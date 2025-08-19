//SystemVerilog
module UniversalShifter #(parameter WIDTH=8) (
    input                  clk,
    input                  rst_n,
    input                  start,
    input        [1:0]     mode,         // 00:hold 01:left 10:right 11:load
    input                  serial_in,
    input  [WIDTH-1:0]     parallel_in,
    output [WIDTH-1:0]     data_out,
    output                 valid_out
);

// Stage 1: Capture inputs and decode mode
reg [1:0]      mode_stage1;
reg            serial_in_stage1;
reg [WIDTH-1:0] parallel_in_stage1;
reg [WIDTH-1:0] data_reg_stage1;
reg            valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_stage1         <= 2'b00;
        serial_in_stage1    <= 1'b0;
        parallel_in_stage1  <= {WIDTH{1'b0}};
        data_reg_stage1     <= {WIDTH{1'b0}};
        valid_stage1        <= 1'b0;
    end else if (start) begin
        mode_stage1         <= mode;
        serial_in_stage1    <= serial_in;
        parallel_in_stage1  <= parallel_in;
        data_reg_stage1     <= data_reg_out;
        valid_stage1        <= 1'b1;
    end else begin
        valid_stage1        <= 1'b0;
    end
end

// Stage 2: Perform shift/load/hold logic
reg [WIDTH-1:0] data_reg_stage2;
reg             valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg_stage2 <= {WIDTH{1'b0}};
        valid_stage2    <= 1'b0;
    end else if (valid_stage1) begin
        case (mode_stage1)
            2'b01: data_reg_stage2 <= {data_reg_stage1[WIDTH-2:0], serial_in_stage1}; // left shift
            2'b10: data_reg_stage2 <= {serial_in_stage1, data_reg_stage1[WIDTH-1:1]}; // right shift
            2'b11: data_reg_stage2 <= parallel_in_stage1;                             // load
            default: data_reg_stage2 <= data_reg_stage1;                              // hold
        endcase
        valid_stage2    <= 1'b1;
    end else begin
        valid_stage2    <= 1'b0;
    end
end

// Stage 3: Output register (optional flush/hold)
reg [WIDTH-1:0] data_reg_out;
reg             valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg_out  <= {WIDTH{1'b0}};
        valid_stage3  <= 1'b0;
    end else if (valid_stage2) begin
        data_reg_out  <= data_reg_stage2;
        valid_stage3  <= 1'b1;
    end else begin
        valid_stage3  <= 1'b0;
    end
end

assign data_out  = data_reg_out;
assign valid_out = valid_stage3;

endmodule