//SystemVerilog
module bram_rom (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] addr,
    output reg [7:0] data,
    output reg data_valid
);

    (* ram_style = "block" *) reg [7:0] rom [0:15];
    
    // Pipeline stage 1 registers
    reg [3:0] addr_stage1;
    reg valid_stage1;
    reg ready_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] data_stage2;
    reg valid_stage2;
    reg ready_stage2;

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
    end

    // Stage 1: Address and control signal processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
            ready_stage1 <= 1'b1;
        end else begin
            if (valid && ready) begin
                addr_stage1 <= addr;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
            ready_stage1 <= ready;
        end
    end

    // Stage 2: ROM access and data output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            ready_stage2 <= 1'b1;
            data_valid <= 1'b0;
            data <= 8'h0;
        end else begin
            if (valid_stage1 && ready_stage1) begin
                data_stage2 <= rom[addr_stage1];
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
            ready_stage2 <= ready_stage1;
            
            // Output stage
            data_valid <= valid_stage2;
            data <= data_stage2;
        end
    end

    // Ready signal generation
    always @(*) begin
        ready = ready_stage2;
    end

endmodule