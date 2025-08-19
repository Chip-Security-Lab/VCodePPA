//SystemVerilog
module fixed_encoder (
    input      [7:0] symbol,
    input            req_in,
    output reg [3:0] code,
    output reg       req_out,
    input            ack_in,
    output reg       ack_out
);
    // Internal state register
    reg processing;
    
    // Signal declarations for multiplexer implementation
    reg [3:0] symbol_code;
    reg req_out_mux;
    reg ack_out_mux;
    wire select_active;
    
    // Generate the selection signal
    assign select_active = req_in && !processing;
    
    // Symbol code lookup using explicit multiplexer structure
    always @(*) begin
        case (symbol[3:0])
            4'h0: symbol_code = 4'h8;
            4'h1: symbol_code = 4'h9;
            4'h2: symbol_code = 4'hA;
            4'h3: symbol_code = 4'hB;
            4'h4: symbol_code = 4'hC;
            4'h5: symbol_code = 4'hD;
            4'h6: symbol_code = 4'hE;
            4'h7: symbol_code = 4'hF;
            4'h8: symbol_code = 4'h0;
            4'h9: symbol_code = 4'h1;
            4'hA: symbol_code = 4'h2;
            4'hB: symbol_code = 4'h3;
            4'hC: symbol_code = 4'h4;
            4'hD: symbol_code = 4'h5;
            4'hE: symbol_code = 4'h6;
            4'hF: symbol_code = 4'h7;
        endcase
    end
    
    // Explicit multiplexer for code output
    always @(*) begin
        case (select_active)
            1'b1: code = symbol_code;
            1'b0: code = 4'h0;
        endcase
    end
    
    // Explicit multiplexer for req_out
    always @(*) begin
        case (select_active)
            1'b1: req_out = 1'b1;
            1'b0: req_out = 1'b0;
        endcase
    end
    
    // Explicit multiplexer for ack_out with independent condition
    always @(*) begin
        if (select_active) begin
            ack_out = 1'b1;
        end else begin
            // Second-level multiplexer
            case (req_in)
                1'b1: ack_out = 1'b1;
                1'b0: ack_out = 1'b0;
            endcase
        end
    end
    
    // Improved process handshake state logic with clearer timing behavior
    always @(req_in, ack_in) begin
        case ({req_in, ack_in})
            2'b11: processing = 1'b1;
            2'b01, 2'b00: processing = 1'b0;
            2'b10: processing = processing; // Hold current value
        endcase
    end
    
endmodule