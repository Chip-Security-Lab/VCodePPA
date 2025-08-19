//SystemVerilog
module random_pulse #(
    parameter LFSR_WIDTH = 8,
    parameter SEED = 8'h2B
)(
    input clk,
    input rst,
    output reg pulse
);

// Main LFSR register
reg [LFSR_WIDTH-1:0] lfsr;
// Buffered copies of LFSR for different purposes
reg [LFSR_WIDTH-1:0] lfsr_buff1;
reg [LFSR_WIDTH-1:0] lfsr_buff2;

// LFSR feedback calculation
wire feedback = lfsr[7] ^ lfsr[3] ^ lfsr[2] ^ lfsr[0];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        lfsr <= SEED;
        lfsr_buff1 <= SEED;
        lfsr_buff2 <= SEED;
        pulse <= 0;
    end else begin
        // Update main LFSR
        lfsr <= {lfsr[LFSR_WIDTH-2:0], feedback};
        
        // Update buffered copies to distribute load
        lfsr_buff1 <= lfsr;
        lfsr_buff2 <= lfsr;
        
        // Use buffered copy for pulse generation to reduce fanout on main LFSR
        pulse <= (lfsr_buff1 < 8'h20);  // 调节生成概率
    end
end

endmodule