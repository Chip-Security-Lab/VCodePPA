//SystemVerilog
// IEEE 1364-2005 Verilog
module RevCounterShift #(parameter N=4) (
    input clk, up_down, load, 
    input [N-1:0] preset,
    output reg [N-1:0] cnt
);

    // Register the control signals to reduce input delay
    reg up_down_reg, load_reg;
    reg [N-1:0] preset_reg;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk) begin
        up_down_reg <= up_down;
        load_reg <= load;
        preset_reg <= preset;
    end
    
    // Pre-compute shift operations after the first register stage
    wire [N-1:0] shift_up = {cnt[N-2:0], cnt[N-1]};
    wire [N-1:0] shift_down = {cnt[0], cnt[N-1:1]};
    wire [N-1:0] next_cnt;
    
    // Use the registered control signals for multiplexing
    assign next_cnt = load_reg ? preset_reg : (up_down_reg ? shift_up : shift_down);
    
    // Final output register
    always @(posedge clk) begin
        cnt <= next_cnt;
    end

endmodule