//SystemVerilog
module eth_preamble_detector (
    input wire clk,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_dv,
    output reg preamble_detected,
    output reg sfd_detected
);
    // Parameter definitions
    localparam PREAMBLE_BYTE = 8'h55;
    localparam SFD_BYTE = 8'hD5;
    
    // FSM state definitions
    localparam IDLE = 2'b00;
    localparam DETECT_PREAMBLE = 2'b01;
    localparam DETECT_SFD = 2'b10;
    
    // Pipeline stage 1: Input registration and byte comparison
    reg [7:0] rx_data_stage1;
    reg rx_dv_stage1;
    reg is_preamble_stage1;
    reg is_sfd_stage1;
    reg [1:0] state_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: State tracking and preamble counting
    reg [7:0] rx_data_stage2;
    reg rx_dv_stage2;
    reg is_preamble_stage2;
    reg is_sfd_stage2;
    reg [1:0] state_stage2;
    reg [1:0] next_state_stage2;
    reg [2:0] preamble_count_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Output signal generation
    reg [1:0] state_stage3;
    reg [1:0] next_state_stage3;
    reg [2:0] preamble_count_stage3;
    reg valid_stage3;
    
    // Pipeline stage 1: Input registration and comparison
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_data_stage1 <= 8'h00;
            rx_dv_stage1 <= 1'b0;
            is_preamble_stage1 <= 1'b0;
            is_sfd_stage1 <= 1'b0;
            state_stage1 <= IDLE;
            valid_stage1 <= 1'b0;
        end else begin
            rx_data_stage1 <= rx_data;
            rx_dv_stage1 <= rx_dv;
            is_preamble_stage1 <= ~(|(rx_data ^ PREAMBLE_BYTE));
            is_sfd_stage1 <= ~(|(rx_data ^ SFD_BYTE));
            state_stage1 <= (state_stage3 == DETECT_SFD && valid_stage3) ? IDLE : state_stage3;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: State tracking and preamble counting
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_data_stage2 <= 8'h00;
            rx_dv_stage2 <= 1'b0;
            is_preamble_stage2 <= 1'b0;
            is_sfd_stage2 <= 1'b0;
            state_stage2 <= IDLE;
            next_state_stage2 <= IDLE;
            preamble_count_stage2 <= 3'd0;
            valid_stage2 <= 1'b0;
        end else begin
            rx_data_stage2 <= rx_data_stage1;
            rx_dv_stage2 <= rx_dv_stage1;
            is_preamble_stage2 <= is_preamble_stage1;
            is_sfd_stage2 <= is_sfd_stage1;
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
            
            // Next state logic
            case (state_stage1)
                IDLE: begin
                    next_state_stage2 <= (rx_dv_stage1 && is_preamble_stage1) ? DETECT_PREAMBLE : IDLE;
                    preamble_count_stage2 <= 3'd0;
                end
                
                DETECT_PREAMBLE: begin
                    if (!rx_dv_stage1)
                        next_state_stage2 <= IDLE;
                    else if (is_sfd_stage1 && preamble_count_stage2 >= 6)
                        next_state_stage2 <= DETECT_SFD;
                    else if (!is_preamble_stage1 && !is_sfd_stage1)
                        next_state_stage2 <= IDLE;
                    else
                        next_state_stage2 <= DETECT_PREAMBLE;
                    
                    // Update preamble counter
                    if (is_preamble_stage1 && rx_dv_stage1)
                        preamble_count_stage2 <= preamble_count_stage2 + 1'b1;
                    else if (!is_preamble_stage1 && !is_sfd_stage1)
                        preamble_count_stage2 <= 3'd0;
                end
                
                DETECT_SFD: begin
                    next_state_stage2 <= IDLE;
                    preamble_count_stage2 <= 3'd0;
                end
                
                default: begin
                    next_state_stage2 <= IDLE;
                    preamble_count_stage2 <= 3'd0;
                end
            endcase
        end
    end
    
    // Pipeline stage 3: Output signal generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage3 <= IDLE;
            next_state_stage3 <= IDLE;
            preamble_count_stage3 <= 3'd0;
            preamble_detected <= 1'b0;
            sfd_detected <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            next_state_stage3 <= next_state_stage2;
            preamble_count_stage3 <= preamble_count_stage2;
            valid_stage3 <= valid_stage2;
            
            // Output signal generation
            case (state_stage2)
                IDLE: begin
                    preamble_detected <= 1'b0;
                    sfd_detected <= 1'b0;
                end
                
                DETECT_PREAMBLE: begin
                    preamble_detected <= (preamble_count_stage2 >= 2) && is_preamble_stage2 && rx_dv_stage2;
                    sfd_detected <= 1'b0;
                end
                
                DETECT_SFD: begin
                    preamble_detected <= 1'b0;
                    sfd_detected <= is_sfd_stage2 && rx_dv_stage2;
                end
                
                default: begin
                    preamble_detected <= 1'b0;
                    sfd_detected <= 1'b0;
                end
            endcase
        end
    end
    
endmodule