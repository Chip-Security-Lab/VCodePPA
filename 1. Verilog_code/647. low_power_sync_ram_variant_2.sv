//SystemVerilog
module low_power_sync_ram_pipelined #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire low_power_mode
);

    // Pipeline registers
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] din_stage1;
    reg we_stage1;
    reg low_power_stage1;
    
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg [DATA_WIDTH-1:0] din_stage2;
    reg we_stage2;
    reg low_power_stage2;
    
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] read_data_stage2;
    
    // Two's complement signals
    wire [DATA_WIDTH-1:0] din_comp;
    wire [DATA_WIDTH-1:0] din_comp_plus1;
    wire [DATA_WIDTH-1:0] din_neg;
    
    // Two's complement logic
    assign din_comp = ~din_stage1;
    assign din_comp_plus1 = din_comp + 1'b1;
    assign din_neg = din_comp_plus1;

    // Stage 1: Address and control signal registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage1 <= 0;
            din_stage1 <= 0;
            we_stage1 <= 0;
            low_power_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            din_stage1 <= din;
            we_stage1 <= we;
            low_power_stage1 <= low_power_mode;
        end
    end

    // Stage 2: Memory access with two's complement
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage2 <= 0;
            din_stage2 <= 0;
            we_stage2 <= 0;
            low_power_stage2 <= 0;
            read_data_stage2 <= 0;
        end else begin
            addr_stage2 <= addr_stage1;
            din_stage2 <= din_neg;  // Use two's complement
            we_stage2 <= we_stage1;
            low_power_stage2 <= low_power_stage1;
            
            if (!low_power_stage1) begin
                if (we_stage1) begin
                    ram[addr_stage1] <= din_neg;  // Use two's complement
                end
                read_data_stage2 <= ram[addr_stage1];
            end
        end
    end

    // Stage 3: Output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (!low_power_stage2) begin
            dout <= read_data_stage2;
        end
    end

endmodule