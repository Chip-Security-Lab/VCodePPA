//SystemVerilog
module sync_quadrupole_ram_two_write #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b, we_c, we_d,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c, addr_d,
    input wire [DATA_WIDTH-1:0] din_a, din_b, din_c, din_d,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, dout_c, dout_d
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Stage 1: Input registers
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1, din_c_stage1, din_d_stage1;
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1, addr_c_stage1, addr_d_stage1;
    reg we_a_stage1, we_b_stage1, we_c_stage1, we_d_stage1;
    
    // Stage 2: Write data registers
    reg [DATA_WIDTH-1:0] write_data_a_stage2, write_data_b_stage2, write_data_c_stage2, write_data_d_stage2;
    reg [ADDR_WIDTH-1:0] write_addr_a_stage2, write_addr_b_stage2, write_addr_c_stage2, write_addr_d_stage2;
    reg write_valid_a_stage2, write_valid_b_stage2, write_valid_c_stage2, write_valid_d_stage2;
    
    // Stage 3: Read address registers
    reg [ADDR_WIDTH-1:0] read_addr_a_stage3, read_addr_b_stage3, read_addr_c_stage3, read_addr_d_stage3;
    
    // Stage 4: Memory read data
    reg [DATA_WIDTH-1:0] read_data_a_stage4, read_data_b_stage4, read_data_c_stage4, read_data_d_stage4;
    
    // Stage 1: Input registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            din_c_stage1 <= 0;
            din_d_stage1 <= 0;
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            addr_c_stage1 <= 0;
            addr_d_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            we_c_stage1 <= 0;
            we_d_stage1 <= 0;
        end else begin
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            din_c_stage1 <= din_c;
            din_d_stage1 <= din_d;
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            addr_c_stage1 <= addr_c;
            addr_d_stage1 <= addr_d;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            we_c_stage1 <= we_c;
            we_d_stage1 <= we_d;
        end
    end
    
    // Stage 2: Write data registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_data_a_stage2 <= 0;
            write_data_b_stage2 <= 0;
            write_data_c_stage2 <= 0;
            write_data_d_stage2 <= 0;
            write_addr_a_stage2 <= 0;
            write_addr_b_stage2 <= 0;
            write_addr_c_stage2 <= 0;
            write_addr_d_stage2 <= 0;
            write_valid_a_stage2 <= 0;
            write_valid_b_stage2 <= 0;
            write_valid_c_stage2 <= 0;
            write_valid_d_stage2 <= 0;
        end else begin
            write_data_a_stage2 <= din_a_stage1;
            write_data_b_stage2 <= din_b_stage1;
            write_data_c_stage2 <= din_c_stage1;
            write_data_d_stage2 <= din_d_stage1;
            write_addr_a_stage2 <= addr_a_stage1;
            write_addr_b_stage2 <= addr_b_stage1;
            write_addr_c_stage2 <= addr_c_stage1;
            write_addr_d_stage2 <= addr_d_stage1;
            write_valid_a_stage2 <= we_a_stage1;
            write_valid_b_stage2 <= we_b_stage1;
            write_valid_c_stage2 <= we_c_stage1;
            write_valid_d_stage2 <= we_d_stage1;
        end
    end
    
    // Stage 3: Read address registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_addr_a_stage3 <= 0;
            read_addr_b_stage3 <= 0;
            read_addr_c_stage3 <= 0;
            read_addr_d_stage3 <= 0;
        end else begin
            read_addr_a_stage3 <= addr_a_stage1;
            read_addr_b_stage3 <= addr_b_stage1;
            read_addr_c_stage3 <= addr_c_stage1;
            read_addr_d_stage3 <= addr_d_stage1;
        end
    end
    
    // Memory write stage (combinational)
    always @(posedge clk) begin
        if (write_valid_a_stage2) ram[write_addr_a_stage2] <= write_data_a_stage2;
        if (write_valid_b_stage2) ram[write_addr_b_stage2] <= write_data_b_stage2;
        if (write_valid_c_stage2) ram[write_addr_c_stage2] <= write_data_c_stage2;
        if (write_valid_d_stage2) ram[write_addr_d_stage2] <= write_data_d_stage2;
    end
    
    // Stage 4: Memory read data registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data_a_stage4 <= 0;
            read_data_b_stage4 <= 0;
            read_data_c_stage4 <= 0;
            read_data_d_stage4 <= 0;
        end else begin
            read_data_a_stage4 <= ram[read_addr_a_stage3];
            read_data_b_stage4 <= ram[read_addr_b_stage3];
            read_data_c_stage4 <= ram[read_addr_c_stage3];
            read_data_d_stage4 <= ram[read_addr_d_stage3];
        end
    end
    
    // Output stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            dout_c <= 0;
            dout_d <= 0;
        end else begin
            dout_a <= read_data_a_stage4;
            dout_b <= read_data_b_stage4;
            dout_c <= read_data_c_stage4;
            dout_d <= read_data_d_stage4;
        end
    end

endmodule