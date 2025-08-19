//SystemVerilog
module tdp_ram_pipelined #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6,
    parameter DEPTH = 64
)(
    input clk,
    input rst_n,
    // Port A
    input [ADDR_WIDTH-1:0] addr_a,
    input [DATA_WIDTH-1:0] din_a,
    output reg [DATA_WIDTH-1:0] dout_a,
    input we_a,
    input valid_a,
    output ready_a,
    // Port B
    input [ADDR_WIDTH-1:0] addr_b,
    input [DATA_WIDTH-1:0] din_b,
    output reg [DATA_WIDTH-1:0] dout_b,
    input we_b,
    input valid_b,
    output ready_b
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// Pipeline stage 1 registers
reg [ADDR_WIDTH-1:0] addr_a_stage1;
reg [DATA_WIDTH-1:0] din_a_stage1;
reg we_a_stage1;
reg valid_a_stage1;

reg [ADDR_WIDTH-1:0] addr_b_stage1;
reg [DATA_WIDTH-1:0] din_b_stage1;
reg we_b_stage1;
reg valid_b_stage1;

// Pipeline stage 2 registers
reg [ADDR_WIDTH-1:0] addr_a_stage2;
reg [ADDR_WIDTH-1:0] addr_b_stage2;
reg we_a_stage2;
reg we_b_stage2;
reg valid_a_stage2;
reg valid_b_stage2;

// Pipeline stage 3 registers
reg [DATA_WIDTH-1:0] dout_a_stage3;
reg [DATA_WIDTH-1:0] dout_b_stage3;
reg valid_a_stage3;
reg valid_b_stage3;

// Ready signals
assign ready_a = 1'b1;
assign ready_b = 1'b1;

// Stage 1: Address and data capture
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_a_stage1 <= 0;
        din_a_stage1 <= 0;
        we_a_stage1 <= 0;
        valid_a_stage1 <= 0;
        addr_b_stage1 <= 0;
        din_b_stage1 <= 0;
        we_b_stage1 <= 0;
        valid_b_stage1 <= 0;
    end else begin
        if (valid_a) begin
            addr_a_stage1 <= addr_a;
            din_a_stage1 <= din_a;
            we_a_stage1 <= we_a;
            valid_a_stage1 <= 1'b1;
        end else begin
            valid_a_stage1 <= 1'b0;
        end

        if (valid_b) begin
            addr_b_stage1 <= addr_b;
            din_b_stage1 <= din_b;
            we_b_stage1 <= we_b;
            valid_b_stage1 <= 1'b1;
        end else begin
            valid_b_stage1 <= 1'b0;
        end
    end
end

// Stage 2: Address and control propagation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_a_stage2 <= 0;
        addr_b_stage2 <= 0;
        we_a_stage2 <= 0;
        we_b_stage2 <= 0;
        valid_a_stage2 <= 0;
        valid_b_stage2 <= 0;
    end else begin
        addr_a_stage2 <= addr_a_stage1;
        addr_b_stage2 <= addr_b_stage1;
        we_a_stage2 <= we_a_stage1;
        we_b_stage2 <= we_b_stage1;
        valid_a_stage2 <= valid_a_stage1;
        valid_b_stage2 <= valid_b_stage1;
    end
end

// Stage 3: Memory access
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_a_stage3 <= 0;
        dout_b_stage3 <= 0;
        valid_a_stage3 <= 0;
        valid_b_stage3 <= 0;
    end else begin
        if (valid_a_stage2) begin
            if (we_a_stage2) begin
                mem[addr_a_stage2] <= din_a_stage1;
                dout_a_stage3 <= din_a_stage1;
            end else begin
                dout_a_stage3 <= mem[addr_a_stage2];
            end
            valid_a_stage3 <= 1'b1;
        end else begin
            valid_a_stage3 <= 1'b0;
        end

        if (valid_b_stage2) begin
            if (we_b_stage2) begin
                mem[addr_b_stage2] <= din_b_stage1;
                dout_b_stage3 <= din_b_stage1;
            end else begin
                dout_b_stage3 <= mem[addr_b_stage2];
            end
            valid_b_stage3 <= 1'b1;
        end else begin
            valid_b_stage3 <= 1'b0;
        end
    end
end

// Output stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_a <= 0;
        dout_b <= 0;
    end else begin
        if (valid_a_stage3) begin
            dout_a <= dout_a_stage3;
        end
        if (valid_b_stage3) begin
            dout_b <= dout_b_stage3;
        end
    end
end

endmodule