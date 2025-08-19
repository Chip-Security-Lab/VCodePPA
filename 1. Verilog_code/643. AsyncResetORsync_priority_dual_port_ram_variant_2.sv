//SystemVerilog
module sync_priority_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,              // 写使能
    input wire read_first,              // 读取优先级信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 输入数据
    output reg [DATA_WIDTH-1:0] dout_a, dout_b  // 输出数据
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Pipeline stage 1: Address and control signal registers
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg read_first_stage1;
    
    // Pipeline stage 2: RAM access and write
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg read_first_stage2;
    
    // Pipeline stage 3: Output selection
    reg [DATA_WIDTH-1:0] ram_data_a_stage3, ram_data_b_stage3;
    reg we_a_stage3, we_b_stage3;
    reg read_first_stage3;
    
    // Stage 1: Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            read_first_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            read_first_stage1 <= read_first;
        end
    end
    
    // Stage 2: RAM access and write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a <= 0;
            ram_data_b <= 0;
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            din_a_stage2 <= 0;
            din_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
            read_first_stage2 <= 0;
        end else begin
            // Read from RAM
            ram_data_a <= ram[addr_a_stage1];
            ram_data_b <= ram[addr_b_stage1];
            
            // Register control signals
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            read_first_stage2 <= read_first_stage1;
            
            // Write to RAM if enabled
            if (we_a_stage1) ram[addr_a_stage1] <= din_a_stage1;
            if (we_b_stage1) ram[addr_b_stage1] <= din_b_stage1;
        end
    end
    
    // Stage 3: Output selection based on priority
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            ram_data_a_stage3 <= 0;
            ram_data_b_stage3 <= 0;
            we_a_stage3 <= 0;
            we_b_stage3 <= 0;
            read_first_stage3 <= 0;
        end else begin
            // Register data from previous stage
            ram_data_a_stage3 <= ram_data_a;
            ram_data_b_stage3 <= ram_data_b;
            we_a_stage3 <= we_a_stage2;
            we_b_stage3 <= we_b_stage2;
            read_first_stage3 <= read_first_stage2;
            
            // Output selection based on priority
            if (read_first_stage2) begin
                dout_a <= ram_data_a;
                dout_b <= ram_data_b;
            end else begin
                dout_a <= ram_data_a;
                dout_b <= ram_data_b;
            end
        end
    end
endmodule