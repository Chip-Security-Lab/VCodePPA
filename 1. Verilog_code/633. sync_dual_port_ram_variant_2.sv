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
    
    // Pipeline stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    
    // Pipeline stage 2 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    
    // Pipeline stage 3 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage3, addr_b_stage3;
    reg [DATA_WIDTH-1:0] ram_data_a_stage3, ram_data_b_stage3;
    
    // Pipeline stage 4 registers
    reg [DATA_WIDTH-1:0] ram_data_a_stage4, ram_data_b_stage4;

    // Carry lookahead subtractor signals
    wire [DATA_WIDTH-1:0] borrow;
    wire [DATA_WIDTH-1:0] borrow_lookahead;
    wire [DATA_WIDTH-1:0] diff_a, diff_b;
    
    // Generate carry lookahead borrow
    assign borrow_lookahead[0] = 1'b0;
    genvar i;
    generate
        for(i = 0; i < DATA_WIDTH-1; i = i + 1) begin : gen_borrow
            assign borrow_lookahead[i+1] = (din_a_stage2[i] < din_b_stage2[i]) || 
                                         ((din_a_stage2[i] == din_b_stage2[i]) && borrow_lookahead[i]);
        end
    endgenerate

    // Calculate difference using carry lookahead
    generate
        for(i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_diff
            assign diff_a[i] = din_a_stage2[i] ^ din_b_stage2[i] ^ borrow_lookahead[i];
            assign diff_b[i] = din_a_stage2[i] ^ din_b_stage2[i] ^ borrow_lookahead[i];
        end
    endgenerate
    
    // Stage 1: Input registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
        end
    end
    
    // Stage 2: Address and write data registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
            din_a_stage2 <= 0;
            din_b_stage2 <= 0;
        end else begin
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
        end
    end
    
    // Stage 3: RAM access and write with carry lookahead subtraction
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage3 <= 0;
            addr_b_stage3 <= 0;
            ram_data_a_stage3 <= 0;
            ram_data_b_stage3 <= 0;
        end else begin
            addr_a_stage3 <= addr_a_stage2;
            addr_b_stage3 <= addr_b_stage2;
            
            if (we_a_stage2) ram[addr_a_stage2] <= diff_a;
            if (we_b_stage2) ram[addr_b_stage2] <= diff_b;
            
            ram_data_a_stage3 <= ram[addr_a_stage2];
            ram_data_b_stage3 <= ram[addr_b_stage2];
        end
    end
    
    // Stage 4: Data registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a_stage4 <= 0;
            ram_data_b_stage4 <= 0;
        end else begin
            ram_data_a_stage4 <= ram_data_a_stage3;
            ram_data_b_stage4 <= ram_data_b_stage3;
        end
    end
    
    // Stage 5: Output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= ram_data_a_stage4;
            dout_b <= ram_data_b_stage4;
        end
    end
endmodule