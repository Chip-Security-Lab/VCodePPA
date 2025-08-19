//SystemVerilog
module sync_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Stage 1 registers
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg [DATA_WIDTH-1:0] ram_data_a_stage1, ram_data_b_stage1;
    
    // Stage 2 registers
    reg [DATA_WIDTH-1:0] temp_a_stage2, temp_b_stage2;
    reg [DATA_WIDTH-1:0] borrow_a_stage2, borrow_b_stage2;
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg we_a_stage2, we_b_stage2;
    
    // Stage 3 registers
    reg [DATA_WIDTH-1:0] result_a_stage3, result_b_stage3;
    reg [ADDR_WIDTH-1:0] addr_a_stage3, addr_b_stage3;
    reg we_a_stage3, we_b_stage3;

    // Stage 1: Address decode and RAM read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            ram_data_a_stage1 <= 0;
            ram_data_b_stage1 <= 0;
        end else begin
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            ram_data_a_stage1 <= ram[addr_a];
            ram_data_b_stage1 <= ram[addr_b];
        end
    end

    // Stage 2: Borrow subtraction calculation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            temp_a_stage2 <= 0;
            temp_b_stage2 <= 0;
            borrow_a_stage2 <= 0;
            borrow_b_stage2 <= 0;
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
        end else begin
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            
            if (we_a_stage1) begin
                temp_a_stage2 <= din_a_stage1;
                borrow_a_stage2 <= 0;
                for (int i = 0; i < DATA_WIDTH; i = i + 1) begin
                    if (temp_a_stage2[i] < ram_data_a_stage1[i]) begin
                        temp_a_stage2[i] <= temp_a_stage2[i] + 2;
                        borrow_a_stage2[i+1] <= 1;
                    end
                    temp_a_stage2[i] <= temp_a_stage2[i] - ram_data_a_stage1[i];
                end
            end

            if (we_b_stage1) begin
                temp_b_stage2 <= din_b_stage1;
                borrow_b_stage2 <= 0;
                for (int i = 0; i < DATA_WIDTH; i = i + 1) begin
                    if (temp_b_stage2[i] < ram_data_b_stage1[i]) begin
                        temp_b_stage2[i] <= temp_b_stage2[i] + 2;
                        borrow_b_stage2[i+1] <= 1;
                    end
                    temp_b_stage2[i] <= temp_b_stage2[i] - ram_data_b_stage1[i];
                end
            end
        end
    end

    // Stage 3: RAM write and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_a_stage3 <= 0;
            result_b_stage3 <= 0;
            addr_a_stage3 <= 0;
            addr_b_stage3 <= 0;
            we_a_stage3 <= 0;
            we_b_stage3 <= 0;
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            addr_a_stage3 <= addr_a_stage2;
            addr_b_stage3 <= addr_b_stage2;
            we_a_stage3 <= we_a_stage2;
            we_b_stage3 <= we_b_stage2;
            
            if (we_a_stage2) begin
                ram[addr_a_stage2] <= temp_a_stage2;
                result_a_stage3 <= temp_a_stage2;
            end else begin
                result_a_stage3 <= ram[addr_a_stage2];
            end

            if (we_b_stage2) begin
                ram[addr_b_stage2] <= temp_b_stage2;
                result_b_stage3 <= temp_b_stage2;
            end else begin
                result_b_stage3 <= ram[addr_b_stage2];
            end

            dout_a <= result_a_stage3;
            dout_b <= result_b_stage3;
        end
    end

endmodule