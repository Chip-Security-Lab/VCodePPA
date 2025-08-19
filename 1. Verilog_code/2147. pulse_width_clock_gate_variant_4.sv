//SystemVerilog
module pulse_width_clock_gate (
    // Clock and reset
    input  wire        clk_in,
    input  wire        rst_n,
    
    // AXI-Stream slave interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [3:0]  s_axis_tdata,
    input  wire        s_axis_tlast,
    
    // Output clock
    output wire        clk_out
);
    reg [3:0] counter_r;
    reg enable_r;
    
    // Move registers forward by pre-computing next state logic
    wire [3:0] next_counter;
    wire next_enable;
    
    // AXI-Stream handshake - ready when counter is not busy
    assign s_axis_tready = (counter_r == 4'd0) && !s_axis_tvalid;
    
    // Detect valid transaction
    wire trigger = s_axis_tvalid && s_axis_tready;
    
    assign next_counter = (!rst_n) ? 4'd0 :
                         trigger ? s_axis_tdata :
                         (|counter_r) ? counter_r - 1'b1 : 4'd0;
    
    assign next_enable = (!rst_n) ? 1'b0 :
                         trigger ? 1'b1 :
                         (|counter_r) ? ((counter_r > 4'd1) ? 1'b1 : 1'b0) : 1'b0;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_r <= 4'd0;
            enable_r <= 1'b0;
        end else begin
            counter_r <= next_counter;
            enable_r <= next_enable;
        end
    end
    
    assign clk_out = clk_in & enable_r;
endmodule