//SystemVerilog
module AutoBaudUART (
    input clk, rst_n,
    input rx_line,
    output reg [15:0] baud_rate,
    output reg baud_locked
);

    localparam SEARCH = 2'b00, MEASURE = 2'b01, LOCKED = 2'b10;
    
    // Stage 1: Input sampling and edge detection
    reg [1:0] current_state_stage1, next_state_stage1;
    reg last_rx_stage1;
    reg edge_detected_stage1;
    
    // Stage 2: Counter and state transition
    reg [1:0] current_state_stage2, next_state_stage2;
    reg [15:0] edge_counter_stage2, next_edge_counter_stage2;
    reg edge_detected_stage2;
    
    // Stage 3: Output generation
    reg [1:0] current_state_stage3;
    reg [15:0] edge_counter_stage3;
    reg edge_detected_stage3;
    
    // Stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_rx_stage1 <= 1;
            current_state_stage1 <= SEARCH;
        end else begin
            last_rx_stage1 <= rx_line;
            current_state_stage1 <= next_state_stage1;
        end
    end
    
    always @(*) begin
        edge_detected_stage1 = (last_rx_stage1 == 1'b1 && rx_line == 1'b0) || 
                             (last_rx_stage1 == 1'b0 && rx_line == 1'b1);
    end
    
    // Stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage2 <= SEARCH;
            edge_counter_stage2 <= 0;
            edge_detected_stage2 <= 0;
        end else begin
            current_state_stage2 <= current_state_stage1;
            edge_counter_stage2 <= next_edge_counter_stage2;
            edge_detected_stage2 <= edge_detected_stage1;
        end
    end
    
    always @(*) begin
        next_state_stage2 = current_state_stage2;
        next_edge_counter_stage2 = edge_counter_stage2;
        
        case(current_state_stage2)
            SEARCH: begin
                next_edge_counter_stage2 = 0;
                if (edge_detected_stage2 && last_rx_stage1 == 1'b1 && rx_line == 1'b0) begin
                    next_state_stage2 = MEASURE;
                end
            end
            MEASURE: begin
                next_edge_counter_stage2 = edge_counter_stage2 + 1;
                if (edge_detected_stage2 && last_rx_stage1 == 1'b0 && rx_line == 1'b1) begin
                    next_state_stage2 = LOCKED;
                end
            end
            LOCKED: begin
                // Keep state
            end
            default: next_state_stage2 = SEARCH;
        endcase
    end
    
    // Stage 3 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage3 <= SEARCH;
            edge_counter_stage3 <= 0;
            edge_detected_stage3 <= 0;
            baud_locked <= 0;
            baud_rate <= 0;
        end else begin
            current_state_stage3 <= current_state_stage2;
            edge_counter_stage3 <= edge_counter_stage2;
            edge_detected_stage3 <= edge_detected_stage2;
            
            if (current_state_stage3 == LOCKED) begin
                baud_locked <= 1;
            end
            
            if (current_state_stage3 == MEASURE && edge_detected_stage3 && 
                last_rx_stage1 == 1'b0 && rx_line == 1'b1) begin
                baud_rate <= edge_counter_stage3;
            end
        end
    end
    
    // Stage 1 state transition
    always @(*) begin
        next_state_stage1 = current_state_stage1;
    end
    
endmodule