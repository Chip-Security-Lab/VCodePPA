//SystemVerilog
module decoder_multi_protocol (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [1:0] mode,
    input [15:0] addr,
    output reg [7:0] select
);

// Pipeline stage 1 registers
reg [1:0] mode_stage1;
reg [15:0] addr_stage1;
reg valid_stage1;
reg ready_stage1;

// Pipeline stage 2 registers
reg [7:0] select_stage2;
reg valid_stage2;
reg ready_stage2;

// Pipeline stage 1: Input sampling
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_stage1 <= 2'b00;
        addr_stage1 <= 16'h0000;
        valid_stage1 <= 1'b0;
        ready_stage1 <= 1'b1;
    end else begin
        if (valid && ready_stage1) begin
            mode_stage1 <= mode;
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
            ready_stage1 <= 1'b0;
        end else if (!valid) begin
            ready_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end
    end
end

// Pipeline stage 2: Protocol decoding
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        select_stage2 <= 8'h00;
        valid_stage2 <= 1'b0;
        ready_stage2 <= 1'b1;
    end else begin
        if (valid_stage1 && ready_stage2) begin
            case(mode_stage1)
                2'b00: select_stage2 <= (addr_stage1[15:12] == 4'h1) ? 8'h01 : 8'h00;  // I2C mode
                2'b01: select_stage2 <= (addr_stage1[7:5] == 3'b101) ? 8'h02 : 8'h00;  // SPI mode
                2'b10: select_stage2 <= (addr_stage1[11:8] > 4'h7) ? 8'h04 : 8'h00;    // AXI mode
                default: select_stage2 <= 8'h00;
            endcase
            valid_stage2 <= 1'b1;
            ready_stage2 <= 1'b0;
        end else if (!valid_stage1) begin
            ready_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
        end
    end
end

// Pipeline stage 3: Output generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        select <= 8'h00;
        ready <= 1'b1;
    end else begin
        if (valid_stage2 && ready) begin
            select <= select_stage2;
            ready <= 1'b0;
        end else if (!valid_stage2) begin
            ready <= 1'b1;
        end
    end
end

endmodule