//SystemVerilog
module sram_clock_gated #(
    parameter DW = 4,
    parameter AW = 3
)(
    input main_clk,
    input rst_n,
    input enable,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg valid_out
);
    // Memory array
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // Clock gating
    wire gated_clk;
    assign gated_clk = main_clk & enable;
    
    // Pipeline registers
    reg [AW-1:0] addr_stage1;
    reg [DW-1:0] din_stage1;
    reg we_stage1;
    reg enable_stage1;
    
    reg [AW-1:0] addr_stage2;
    reg [DW-1:0] din_stage2;
    reg we_stage2;
    reg enable_stage2;
    
    reg [DW-1:0] mem_data_stage2;
    reg [DW-1:0] mem_data_stage3;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // Stage 1: Address and data capture
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            din_stage1 <= 0;
            we_stage1 <= 0;
            enable_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            din_stage1 <= din;
            we_stage1 <= we;
            enable_stage1 <= enable;
            valid_stage1 <= enable;
        end
    end
    
    // Stage 2: Memory access
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 0;
            din_stage2 <= 0;
            we_stage2 <= 0;
            enable_stage2 <= 0;
            valid_stage2 <= 0;
            mem_data_stage2 <= 0;
        end else begin
            addr_stage2 <= addr_stage1;
            din_stage2 <= din_stage1;
            we_stage2 <= we_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
            mem_data_stage2 <= mem[addr_stage1];
        end
    end
    
    // Stage 3: Write operation and output generation
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_data_stage3 <= 0;
            valid_stage3 <= 0;
            dout <= 0;
            valid_out <= 0;
        end else begin
            if (we_stage2 && enable_stage2) begin
                mem[addr_stage2] <= din_stage2;
                mem_data_stage3 <= din_stage2;
            end else begin
                mem_data_stage3 <= mem_data_stage2;
            end
            
            valid_stage3 <= valid_stage2;
            dout <= mem_data_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule