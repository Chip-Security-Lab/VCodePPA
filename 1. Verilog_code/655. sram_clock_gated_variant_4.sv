//SystemVerilog
module sram_clock_gated #(
    parameter DW = 4,
    parameter AW = 3
)(
    input main_clk,
    input rst_n,           // Added reset signal for pipeline registers
    input enable,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    input valid_in,        // Input valid signal
    output reg valid_out,  // Output valid signal
    output reg [DW-1:0] dout
);
    // Memory array
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // Pipeline stage 1 registers
    reg enable_stage1, we_stage1;
    reg [AW-1:0] addr_stage1;
    reg [DW-1:0] din_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg enable_stage2, we_stage2;
    reg [AW-1:0] addr_stage2;
    reg [DW-1:0] din_stage2;
    reg valid_stage2;
    reg [DW-1:0] read_data_stage2;
    
    // Pipeline stage 1: Register input signals
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1 <= 1'b0;
            we_stage1 <= 1'b0;
            addr_stage1 <= {AW{1'b0}};
            din_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            enable_stage1 <= enable;
            we_stage1 <= we;
            addr_stage1 <= addr;
            din_stage1 <= din;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2: Memory access
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage2 <= 1'b0;
            we_stage2 <= 1'b0;
            addr_stage2 <= {AW{1'b0}};
            din_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
            read_data_stage2 <= {DW{1'b0}};
        end else begin
            enable_stage2 <= enable_stage1;
            we_stage2 <= we_stage1;
            addr_stage2 <= addr_stage1;
            din_stage2 <= din_stage1;
            valid_stage2 <= valid_stage1;
            
            if (enable_stage1 && valid_stage1) begin
                if (we_stage1) begin
                    mem[addr_stage1] <= din_stage1;
                    read_data_stage2 <= din_stage1; // Write-through behavior
                end else begin
                    read_data_stage2 <= mem[addr_stage1];
                end
            end
        end
    end
    
    // Pipeline stage 3: Output register
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2 && enable_stage2;
            if (valid_stage2 && enable_stage2) begin
                dout <= read_data_stage2;
            end
        end
    end
endmodule