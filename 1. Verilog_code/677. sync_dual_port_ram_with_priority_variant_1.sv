//SystemVerilog
module sync_dual_port_ram_with_priority #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire read_first,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Stage 1: Address and control signal registration
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg read_first_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    
    // Stage 2: Memory access and write data registration
    reg [DATA_WIDTH-1:0] read_data_a_stage2, read_data_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg read_first_stage2;
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    
    // Stage 3: Output registration
    reg [DATA_WIDTH-1:0] read_data_a_stage3, read_data_b_stage3;
    reg we_a_stage3, we_b_stage3;
    reg read_first_stage3;
    reg [ADDR_WIDTH-1:0] addr_a_stage3, addr_b_stage3;
    reg [DATA_WIDTH-1:0] din_a_stage3, din_b_stage3;

    // Stage 1: Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            read_first_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            read_first_stage1 <= read_first;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
        end
    end

    // Stage 2: Memory read and write data registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data_a_stage2 <= 0;
            read_data_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
            read_first_stage2 <= 0;
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            din_a_stage2 <= 0;
            din_b_stage2 <= 0;
        end else begin
            read_data_a_stage2 <= ram[addr_a_stage1];
            read_data_b_stage2 <= ram[addr_b_stage1];
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            read_first_stage2 <= read_first_stage1;
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
        end
    end

    // Stage 3: Memory write and output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data_a_stage3 <= 0;
            read_data_b_stage3 <= 0;
            we_a_stage3 <= 0;
            we_b_stage3 <= 0;
            read_first_stage3 <= 0;
            addr_a_stage3 <= 0;
            addr_b_stage3 <= 0;
            din_a_stage3 <= 0;
            din_b_stage3 <= 0;
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            read_data_a_stage3 <= read_data_a_stage2;
            read_data_b_stage3 <= read_data_b_stage2;
            we_a_stage3 <= we_a_stage2;
            we_b_stage3 <= we_b_stage2;
            read_first_stage3 <= read_first_stage2;
            addr_a_stage3 <= addr_a_stage2;
            addr_b_stage3 <= addr_b_stage2;
            din_a_stage3 <= din_a_stage2;
            din_b_stage3 <= din_b_stage2;

            if (read_first_stage2) begin
                if (we_a_stage2) ram[addr_a_stage2] <= din_a_stage2;
                if (we_b_stage2) ram[addr_b_stage2] <= din_b_stage2;
            end else begin
                if (we_a_stage2) ram[addr_a_stage2] <= din_a_stage2;
                if (we_b_stage2) ram[addr_b_stage2] <= din_b_stage2;
            end
        end
    end

    // Final output stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            if (read_first_stage3) begin
                dout_a <= read_data_a_stage3;
                dout_b <= read_data_b_stage3;
            end else begin
                dout_a <= read_data_a_stage3;
                dout_b <= read_data_b_stage3;
            end
        end
    end

endmodule