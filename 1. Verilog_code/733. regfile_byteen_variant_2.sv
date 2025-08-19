//SystemVerilog
module regfile_byteen #(
    parameter WIDTH = 32,
    parameter ADDRW = 4
)(
    input clk,
    input rst,
    input [3:0] byte_en,
    input [ADDRW-1:0] addr,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] reg_bank [0:(1<<ADDRW)-1];
    
    // Pipeline stage 1: Register address and data inputs
    reg [ADDRW-1:0] addr_r;
    reg [WIDTH-1:0] din_r;
    reg [3:0] byte_en_r;
    
    // Pipeline stage 2: Register fetched data for byte selection logic
    reg [WIDTH-1:0] current_r;
    
    // Data output register to break critical path from memory to output
    reg [WIDTH-1:0] dout_r;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk) begin
        addr_r <= addr;
        din_r <= din;
        byte_en_r <= byte_en;
    end
    
    // Pipeline stage 2: Fetch current value
    always @(posedge clk) begin
        current_r <= reg_bank[addr_r];
    end
    
    // Write operation with pipelined inputs
    always @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i=0; i<(1<<ADDRW); i=i+1) 
                reg_bank[i] <= 0;
        end else begin
            reg_bank[addr_r] <= {
                byte_en_r[3] ? din_r[31:24] : current_r[31:24],
                byte_en_r[2] ? din_r[23:16] : current_r[23:16],
                byte_en_r[1] ? din_r[15:8] : current_r[15:8],
                byte_en_r[0] ? din_r[7:0] : current_r[7:0]
            };
        end
    end
    
    // Output stage with registered read data
    always @(posedge clk) begin
        dout_r <= reg_bank[addr];
    end
    
    assign dout = dout_r;
endmodule