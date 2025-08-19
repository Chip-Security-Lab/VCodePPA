//SystemVerilog
module pipelined_barrel_shifter (
    input              clk,
    input              rst,
    input      [31:0]  data_in,
    input      [4:0]   shift,
    output reg [31:0]  data_out
);

// Stage 1 registers
reg [31:0] data_stage1;
reg [4:0]  shift_stage1;
reg        valid_stage1;
reg        valid_in;

// Stage 2 registers
reg [31:0] data_stage2;
reg [4:0]  shift_stage2;
reg        valid_stage2;

// Stage 3 registers
reg [31:0] data_stage3;
reg        valid_stage3;

//-----------------------------
// Stage 1: Data Path
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_stage1 <= 32'b0;
    end else begin
        if (shift[4])
            data_stage1 <= {data_in[15:0], 16'b0};
        else
            data_stage1 <= data_in;
    end
end

// Stage 1: Shift Path
always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_stage1 <= 5'b0;
    end else begin
        shift_stage1 <= shift;
    end
end

// Stage 1: Valid Path
always @(posedge clk or posedge rst) begin
    if (rst) begin
        valid_stage1 <= 1'b0;
        valid_in <= 1'b0;
    end else begin
        valid_stage1 <= 1'b1;
        valid_in <= 1'b1;
    end
end

//-----------------------------
// Stage 2: Data Path
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_stage2 <= 32'b0;
    end else begin
        if (shift_stage1[3])
            data_stage2 <= {data_stage1[23:0], 8'b0};
        else
            data_stage2 <= data_stage1;
    end
end

// Stage 2: Shift Path
always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_stage2 <= 5'b0;
    end else begin
        shift_stage2 <= shift_stage1;
    end
end

// Stage 2: Valid Path
always @(posedge clk or posedge rst) begin
    if (rst) begin
        valid_stage2 <= 1'b0;
    end else begin
        valid_stage2 <= valid_stage1;
    end
end

//-----------------------------
// Stage 3: Data Path
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_stage3 <= 32'b0;
    end else begin
        if (shift_stage2[2:0] != 3'b000)
            data_stage3 <= data_stage2 << shift_stage2[2:0];
        else
            data_stage3 <= data_stage2;
    end
end

// Stage 3: Valid Path
always @(posedge clk or posedge rst) begin
    if (rst) begin
        valid_stage3 <= 1'b0;
    end else begin
        valid_stage3 <= valid_stage2;
    end
end

//-----------------------------
// Output Register
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= 32'b0;
    end else if (valid_stage3) begin
        data_out <= data_stage3;
    end
end

endmodule