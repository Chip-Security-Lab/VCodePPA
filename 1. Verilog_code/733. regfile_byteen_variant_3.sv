//SystemVerilog
module regfile_byteen_pipelined #(
    parameter WIDTH = 32,
    parameter ADDRW = 4
)(
    input clk,
    input rst,
    input valid_in,
    output ready_in,
    input [3:0] byte_en,
    input [ADDRW-1:0] addr,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout,
    output valid_out
);

// Pipeline stage registers
reg [3:0] byte_en_stage1;
reg [ADDRW-1:0] addr_stage1, addr_stage2;
reg [WIDTH-1:0] din_stage1;
reg valid_stage1, valid_stage2;
reg [WIDTH-1:0] current_stage1;

// Register file
reg [WIDTH-1:0] reg_bank [0:(1<<ADDRW)-1];

// Control signals
assign ready_in = 1'b1;
assign valid_out = valid_stage2;

// Pre-compute byte enable masks
wire [WIDTH-1:0] byte_mask;
assign byte_mask = {
    {8{byte_en[3]}},
    {8{byte_en[2]}},
    {8{byte_en[1]}},
    {8{byte_en[0]}}
};

// First pipeline stage
always @(posedge clk) begin
    if (rst) begin
        byte_en_stage1 <= 4'b0;
        addr_stage1 <= {ADDRW{1'b0}};
        din_stage1 <= {WIDTH{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        if (valid_in && ready_in) begin
            byte_en_stage1 <= byte_en;
            addr_stage1 <= addr;
            din_stage1 <= din;
            current_stage1 <= reg_bank[addr];
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
end

// Second pipeline stage
integer i;
always @(posedge clk) begin
    if (rst) begin
        for (i=0; i<(1<<ADDRW); i=i+1) reg_bank[i] <= 0;
        addr_stage2 <= {ADDRW{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        if (valid_stage1) begin
            // Write logic with balanced path
            reg_bank[addr_stage1] <= (din_stage1 & byte_mask) | (current_stage1 & ~byte_mask);
            
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
end

// Read logic
assign dout = reg_bank[addr_stage2];

endmodule