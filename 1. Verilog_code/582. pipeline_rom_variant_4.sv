//SystemVerilog
module pipeline_rom (
    input clk,
    input [3:0] addr,
    input valid,
    output reg ready,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [7:0] stage1, stage2;
    reg valid_stage1, valid_stage2;
    reg [3:0] addr_reg;

    // ROM initialization
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
        ready = 1'b1;
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
    end

    // Stage 0: Address registration and valid signal propagation
    always @(posedge clk) begin
        if (valid && ready) begin
            addr_reg <= addr;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 1: ROM data access and valid signal propagation
    always @(posedge clk) begin
        if (valid_stage1) begin
            stage1 <= rom[addr_reg];
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 2: Output data registration
    always @(posedge clk) begin
        if (valid_stage2) begin
            data <= stage1;
        end
    end
endmodule