//SystemVerilog
module eth_addr_checker (
    input clk,
    input reset_n,
    input [47:0] mac_addr,
    input [47:0] received_addr,
    input addr_valid,
    output reg addr_match,
    output reg broadcast_detected,
    output reg multicast_detected
);
    // Define control states
    localparam RESET_STATE = 2'b00;
    localparam VALID_STATE = 2'b01;
    localparam IDLE_STATE  = 2'b10;
    
    // Control state variable
    wire [1:0] control_state;
    
    // Combinational logic for state determination
    assign control_state = (!reset_n) ? RESET_STATE :
                          (addr_valid) ? VALID_STATE : IDLE_STATE;
    
    // Combinational logic signals
    wire addr_match_comb;
    wire broadcast_detected_comb;
    wire multicast_detected_comb;
    
    // Combinational logic for output calculations
    assign addr_match_comb = (control_state == VALID_STATE) ? (mac_addr == received_addr) : 1'b0;
    assign broadcast_detected_comb = (control_state == VALID_STATE) ? &received_addr[47:0] : 1'b0;
    assign multicast_detected_comb = (control_state == VALID_STATE) ? received_addr[0] : 1'b0;
    
    // Sequential logic for output registers
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            addr_match <= 1'b0;
            broadcast_detected <= 1'b0;
            multicast_detected <= 1'b0;
        end
        else begin
            addr_match <= addr_match_comb;
            broadcast_detected <= broadcast_detected_comb;
            multicast_detected <= multicast_detected_comb;
        end
    end
endmodule