//SystemVerilog
module sync_dual_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [ADDR_WIDTH-1:0] addr_a_pipe [1:0];
    reg [ADDR_WIDTH-1:0] addr_b_pipe [1:0];
    reg [DATA_WIDTH-1:0] din_a_pipe [1:0];
    reg [DATA_WIDTH-1:0] din_b_pipe [1:0];
    reg we_a_pipe [1:0];
    reg we_b_pipe [1:0];
    reg en_pipe [1:0];
    
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    // Pipeline stage 1
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_pipe[0] <= 0;
            addr_b_pipe[0] <= 0;
            din_a_pipe[0] <= 0;
            din_b_pipe[0] <= 0;
            we_a_pipe[0] <= 0;
            we_b_pipe[0] <= 0;
            en_pipe[0] <= 0;
        end else begin
            addr_a_pipe[0] <= addr_a;
            addr_b_pipe[0] <= addr_b;
            din_a_pipe[0] <= din_a;
            din_b_pipe[0] <= din_b;
            we_a_pipe[0] <= we_a;
            we_b_pipe[0] <= we_b;
            en_pipe[0] <= en;
        end
    end

    // Pipeline stage 2
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_pipe[1] <= 0;
            addr_b_pipe[1] <= 0;
            din_a_pipe[1] <= 0;
            din_b_pipe[1] <= 0;
            we_a_pipe[1] <= 0;
            we_b_pipe[1] <= 0;
            en_pipe[1] <= 0;
        end else begin
            addr_a_pipe[1] <= addr_a_pipe[0];
            addr_b_pipe[1] <= addr_b_pipe[0];
            din_a_pipe[1] <= din_a_pipe[0];
            din_b_pipe[1] <= din_b_pipe[0];
            we_a_pipe[1] <= we_a_pipe[0];
            we_b_pipe[1] <= we_b_pipe[0];
            en_pipe[1] <= en_pipe[0];
        end
    end

    // Memory access and output stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else if (en_pipe[1]) begin
            if (we_a_pipe[1]) ram[addr_a_pipe[1]] <= din_a_pipe[1];
            if (we_b_pipe[1]) ram[addr_b_pipe[1]] <= din_b_pipe[1];
            dout_a <= ram[addr_a_pipe[1]];
            dout_b <= ram[addr_b_pipe[1]];
        end
    end
endmodule