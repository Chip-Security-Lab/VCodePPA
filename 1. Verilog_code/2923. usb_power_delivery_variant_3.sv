//SystemVerilog
module usb_power_delivery(
    input wire clk,
    input wire rst_n,
    input wire cc1_in,
    input wire cc2_in,
    input wire pd_negotiation_start,
    input wire [7:0] supported_pdo_count,
    input wire [31:0] source_pdo_1,
    input wire [31:0] source_pdo_2,
    output reg cc1_out,
    output reg cc2_out,
    output reg cc1_oe,
    output reg cc2_oe,
    output reg [2:0] pd_state,
    output reg [1:0] cc_polarity,
    output reg [31:0] selected_pdo,
    output reg pd_contract_established
);
    // PD state machine states (binary encoding for better synthesis)
    localparam [2:0] IDLE    = 3'b000;
    localparam [2:0] SRC_CAP = 3'b001;
    localparam [2:0] REQUEST = 3'b010;
    localparam [2:0] ACCEPT  = 3'b011;
    localparam [2:0] PS_RDY  = 3'b100;
    
    reg [2:0] fsm_state; // Binary encoded state register
    reg [7:0] message_counter;
    reg active_cc; // 0 = CC1, 1 = CC2
    
    // Direct state mapping for output
    assign pd_state = fsm_state;
    
    // CC polarity detection logic
    wire cc1_active = cc1_in && !cc2_in;
    wire cc2_active = !cc1_in && cc2_in;
    wire any_cc_active = cc1_in || cc2_in;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state <= IDLE;
            cc1_out <= 1'b0;
            cc2_out <= 1'b0;
            cc1_oe <= 1'b0;
            cc2_oe <= 1'b0;
            cc_polarity <= 2'b00;
            selected_pdo <= 32'd0;
            pd_contract_established <= 1'b0;
            message_counter <= 8'd0;
            active_cc <= 1'b0;
        end else begin
            case (fsm_state)
                IDLE: begin
                    // Optimized CC pin connection detection
                    if (cc1_active) begin
                        cc_polarity <= 2'b01; // CC1 active
                        active_cc <= 1'b0;
                    end else if (cc2_active) begin
                        cc_polarity <= 2'b10; // CC2 active
                        active_cc <= 1'b1;
                    end
                    
                    // Use pre-computed condition
                    fsm_state <= (pd_negotiation_start && any_cc_active) ? SRC_CAP : IDLE;
                end
                
                SRC_CAP: begin
                    // Pipelined message counter increment with threshold comparison
                    if (message_counter < 8'd9) begin
                        message_counter <= message_counter + 8'd1;
                    end else begin
                        fsm_state <= REQUEST;
                        message_counter <= 8'd0;
                    end
                end
                
                REQUEST: begin
                    // Additional state implementation
                    fsm_state <= ACCEPT;
                end
                
                ACCEPT: begin
                    // Additional state implementation
                    fsm_state <= PS_RDY;
                end
                
                PS_RDY: begin
                    // Contract established
                    pd_contract_established <= 1'b1;
                    
                    // Select appropriate PDO based on negotiation (simplified)
                    selected_pdo <= (supported_pdo_count > 1) ? source_pdo_2 : source_pdo_1;
                    
                    // Stay in this state until reset
                end
                
                default: begin
                    fsm_state <= IDLE;
                end
            endcase
        end
    end
    
    // Optimized CC output enable logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cc1_oe <= 1'b0;
            cc2_oe <= 1'b0;
        end else begin
            cc1_oe <= (fsm_state != IDLE) && (active_cc == 1'b0);
            cc2_oe <= (fsm_state != IDLE) && (active_cc == 1'b1);
        end
    end
    
endmodule