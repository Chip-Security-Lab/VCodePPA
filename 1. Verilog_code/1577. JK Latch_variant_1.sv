//SystemVerilog
// JK Latch Control Logic Module
module jk_latch_control (
    input wire j,
    input wire k,
    output reg [1:0] control_signal
);
    always @* begin
        case ({j, k})
            2'b00: control_signal = 2'b00;  // Hold
            2'b01: control_signal = 2'b01;  // Reset
            2'b10: control_signal = 2'b10;  // Set
            2'b11: control_signal = 2'b11;  // Toggle
        endcase
    end
endmodule

// JK Latch Output Logic Module with Baugh-Wooley Multiplier
module jk_latch_output (
    input wire [1:0] control_signal,
    input wire enable,
    input wire current_state,
    output reg next_state
);
    wire [1:0] bw_product;
    wire [1:0] bw_a = {1'b0, current_state};
    wire [1:0] bw_b = {1'b0, control_signal[0]};
    
    // Baugh-Wooley 2-bit multiplier implementation
    assign bw_product[0] = bw_a[0] & bw_b[0];
    assign bw_product[1] = (bw_a[1] & bw_b[0]) ^ (bw_a[0] & bw_b[1]);
    
    always @* begin
        if (enable) begin
            case (control_signal)
                2'b00: next_state = current_state;  // Hold
                2'b01: next_state = 1'b0;           // Reset
                2'b10: next_state = 1'b1;           // Set
                2'b11: next_state = bw_product[0];  // Toggle using Baugh-Wooley
            endcase
        end else begin
            next_state = current_state;
        end
    end
endmodule

// JK Latch State Register Module
module jk_latch_state_reg (
    input wire clk,
    input wire reset_n,
    input wire next_state,
    output reg q
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            q <= 1'b0;
        else
            q <= next_state;
    end
endmodule

// Top-level JK Latch Module
module jk_latch (
    input wire j,
    input wire k,
    input wire enable,
    input wire clk,
    input wire reset_n,
    output wire q
);
    wire [1:0] control_signal;
    wire next_state;
    
    // Instantiate control logic module
    jk_latch_control control_unit (
        .j(j),
        .k(k),
        .control_signal(control_signal)
    );
    
    // Instantiate output logic module
    jk_latch_output output_unit (
        .control_signal(control_signal),
        .enable(enable),
        .current_state(q),
        .next_state(next_state)
    );
    
    // Instantiate state register module
    jk_latch_state_reg state_reg (
        .clk(clk),
        .reset_n(reset_n),
        .next_state(next_state),
        .q(q)
    );
endmodule