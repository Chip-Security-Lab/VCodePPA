//SystemVerilog
// State decoder module
module state_decoder(
    input wire [1:0] state,
    input wire [1:0] event_in,
    output reg [1:0] next_state
);
    localparam [1:0] S0 = 2'b00, S1 = 2'b01, 
                    S2 = 2'b10, S3 = 2'b11;
    
    always @(*) begin
        case ({state, event_in})
            4'b0000: next_state = S0;
            4'b0001: next_state = S1;
            4'b0010: next_state = S0;
            4'b0011: next_state = S2;
            4'b0100: next_state = S0;
            4'b0101: next_state = S1;
            4'b0110: next_state = S3;
            4'b0111: next_state = S2;
            4'b1000: next_state = S0;
            4'b1001: next_state = S1;
            4'b1010: next_state = S3;
            4'b1011: next_state = S2;
            4'b1100: next_state = S0;
            4'b1101: next_state = S0;
            4'b1110: next_state = S0;
            4'b1111: next_state = S0;
            default: next_state = S0;
        endcase
    end
endmodule

// Detection logic module
module detection_logic(
    input wire [1:0] state,
    input wire [1:0] event_in,
    output reg detected
);
    always @(*) begin
        detected = 1'b0;
        if (state == 2'b11) begin
            detected = 1'b1;
        end
    end
endmodule

// State register module
module state_register(
    input wire clk,
    input wire rst_n,
    input wire [1:0] next_state,
    output reg [1:0] current_state
);
    localparam [1:0] S0 = 2'b00;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) current_state <= S0;
        else current_state <= next_state;
endmodule

// Top-level event detector module
module event_detector(
    input wire clk, rst_n,
    input wire [1:0] event_in,
    output wire detected
);
    localparam [1:0] S0 = 2'b00, S1 = 2'b01, 
                    S2 = 2'b10, S3 = 2'b11;
    
    wire [1:0] current_state, next_state;
    
    // Instantiate state register
    state_register state_reg(
        .clk(clk),
        .rst_n(rst_n),
        .next_state(next_state),
        .current_state(current_state)
    );
    
    // Instantiate state decoder
    state_decoder state_dec(
        .state(current_state),
        .event_in(event_in),
        .next_state(next_state)
    );
    
    // Instantiate detection logic
    detection_logic det_logic(
        .state(current_state),
        .event_in(event_in),
        .detected(detected)
    );
endmodule