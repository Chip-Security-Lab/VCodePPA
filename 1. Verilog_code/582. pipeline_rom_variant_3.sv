//SystemVerilog
module pipeline_rom (
    input clk,
    input rst_n,
    input [3:0] addr,
    input valid_in,
    output reg [7:0] data,
    output reg valid_out
);

    reg [7:0] rom [0:15];
    
    // Pipeline registers
    reg [7:0] data_stage1, data_stage2, data_stage3, data_stage4, data_stage5;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    reg [3:0] addr_stage1, addr_stage2, addr_stage3;

    // ROM initialization
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
        rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC;
        rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h11; rom[9] = 8'h22;
        rom[10] = 8'h33; rom[11] = 8'h44;
        rom[12] = 8'h55; rom[13] = 8'h66;
        rom[14] = 8'h77; rom[15] = 8'h88;
    end

    // Stage 1: Address registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: ROM access preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: ROM data fetch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'h00;
            addr_stage3 <= 4'h0;
            valid_stage3 <= 1'b0;
        end else begin
            data_stage1 <= rom[addr_stage2];
            addr_stage3 <= addr_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Data processing 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'h00;
            valid_stage4 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            valid_stage4 <= valid_stage3;
        end
    end

    // Stage 5: Data processing 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 8'h00;
            valid_stage5 <= 1'b0;
        end else begin
            data_stage3 <= data_stage2;
            valid_stage5 <= valid_stage4;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'h00;
            valid_out <= 1'b0;
        end else begin
            data <= data_stage3;
            valid_out <= valid_stage5;
        end
    end

endmodule