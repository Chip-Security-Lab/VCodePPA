module tdp_ram_bist #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk, 
    input bist_start,
    output reg bist_done,
    output reg [15:0] error_count,
    // User ports
    input [AW-1:0] user_addr,
    input [DW-1:0] user_din,
    output [DW-1:0] user_dout,
    input user_we,
    // Test ports
    input [AW-1:0] test_addr,
    input [DW-1:0] test_din,
    output [DW-1:0] test_dout,
    input test_we
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [1:0] bist_state;
reg [AW-1:0] bist_addr;

assign user_dout = mem[user_addr];
assign test_dout = mem[test_addr];

always @(posedge clk) begin
    // User port
    if (user_we) mem[user_addr] <= user_din;
    
    // Test port
    if (test_we) mem[test_addr] <= test_din;
    
    // BIST control
    case(bist_state)
        0: if (bist_start) begin
            bist_state <= 1;
            bist_addr <= 0;
            error_count <= 0;
            bist_done <= 0;
        end
        1: begin // Write test pattern
            mem[bist_addr] <= bist_addr;
            if (&bist_addr) bist_state <= 2;
            else bist_addr <= bist_addr + 1;
        end
        2: begin // Read verification
            // Check if the memory value matches the expected pattern
            if (mem[bist_addr] !== bist_addr) 
                error_count <= error_count + 1;
                
            // Always increment the address or move to next state
            if (&bist_addr) 
                bist_state <= 3;
            else 
                bist_addr <= bist_addr + 1;
        end
        3: bist_done <= 1;
    endcase
end
endmodule