//SystemVerilog
module lcd_controller(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire start_xfer,
    output reg rs, rw, e,
    output reg [7:0] data_out,
    output reg busy,
    output reg ready
);
    localparam IDLE=3'd0, SETUP=3'd1, ENABLE=3'd2, HOLD=3'd3, DISABLE=3'd4;
    
    reg [2:0] stage1_state, stage1_next;
    reg [2:0] stage2_state, stage2_next;
    reg [2:0] stage3_state, stage3_next;
    
    reg [7:0] stage1_data, stage2_data, stage3_data;
    reg stage1_rs, stage2_rs, stage3_rs;
    reg stage1_valid, stage2_valid, stage3_valid;
    reg [7:0] stage1_delay_cnt, stage2_delay_cnt, stage3_delay_cnt;
    reg stage1_busy, stage2_busy, stage3_busy;
    reg stage1_e, stage2_e, stage3_e;
    
    // Pipeline registers for critical path
    reg [7:0] data_in_reg;
    reg start_xfer_reg;
    reg [2:0] state_reg;
    reg [7:0] delay_cnt_reg;
    reg valid_reg;
    reg busy_reg;
    reg e_reg;
    
    // Stage 1: Input handling and initial state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_state <= IDLE;
            stage1_data <= 8'd0;
            stage1_rs <= 1'b0;
            stage1_delay_cnt <= 8'd0;
            stage1_valid <= 1'b0;
            stage1_busy <= 1'b0;
            data_in_reg <= 8'd0;
            start_xfer_reg <= 1'b0;
            state_reg <= IDLE;
            delay_cnt_reg <= 8'd0;
            valid_reg <= 1'b0;
            busy_reg <= 1'b0;
            e_reg <= 1'b0;
        end else begin
            // Register inputs
            data_in_reg <= data_in;
            start_xfer_reg <= start_xfer;
            
            // Pipeline stage 1
            stage1_state <= state_reg;
            stage1_data <= data_in_reg;
            stage1_rs <= data_in_reg[7];
            stage1_delay_cnt <= delay_cnt_reg;
            stage1_valid <= valid_reg;
            stage1_busy <= busy_reg;
            stage1_e <= e_reg;
            
            // Update pipeline registers
            state_reg <= stage1_next;
            delay_cnt_reg <= (stage1_state != stage1_next) ? 8'd0 : 
                           (stage1_state != IDLE) ? stage1_delay_cnt + 8'd1 : stage1_delay_cnt;
            valid_reg <= (stage1_state == IDLE && start_xfer_reg && ready) ? 1'b1 :
                        (stage1_state != IDLE) ? 1'b1 : 1'b0;
            busy_reg <= (stage1_next != IDLE);
            e_reg <= (stage1_state == ENABLE || stage1_state == HOLD);
        end
    end
    
    // Stage 1 next state logic
    always @(*) begin
        case (stage1_state)
            IDLE: stage1_next = (start_xfer_reg && ready) ? SETUP : IDLE;
            SETUP: stage1_next = (stage1_delay_cnt >= 8'd5) ? ENABLE : SETUP;
            ENABLE: stage1_next = (stage1_delay_cnt >= 8'd10) ? HOLD : ENABLE;
            HOLD: stage1_next = (stage1_delay_cnt >= 8'd20) ? DISABLE : HOLD;
            DISABLE: stage1_next = (stage1_delay_cnt >= 8'd5) ? IDLE : DISABLE;
            default: stage1_next = IDLE;
        endcase
    end
    
    // Stage 2: Middle processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_state <= IDLE;
            stage2_data <= 8'd0;
            stage2_rs <= 1'b0;
            stage2_delay_cnt <= 8'd0;
            stage2_valid <= 1'b0;
            stage2_busy <= 1'b0;
            stage2_e <= 1'b0;
        end else begin
            stage2_state <= stage1_state;
            stage2_next <= stage1_next;
            stage2_data <= stage1_data;
            stage2_rs <= stage1_rs;
            stage2_delay_cnt <= stage1_delay_cnt;
            stage2_valid <= stage1_valid;
            stage2_busy <= stage1_busy;
            stage2_e <= stage1_e;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_state <= IDLE;
            stage3_data <= 8'd0;
            stage3_rs <= 1'b0;
            stage3_delay_cnt <= 8'd0;
            stage3_valid <= 1'b0;
            stage3_busy <= 1'b0;
            stage3_e <= 1'b0;
            data_out <= 8'd0;
            rs <= 1'b0;
            rw <= 1'b0;
            e <= 1'b0;
            busy <= 1'b0;
        end else begin
            stage3_state <= stage2_state;
            stage3_next <= stage2_next;
            stage3_data <= stage2_data;
            stage3_rs <= stage2_rs;
            stage3_delay_cnt <= stage2_delay_cnt;
            stage3_valid <= stage2_valid;
            stage3_busy <= stage2_busy;
            stage3_e <= stage2_e;
            
            data_out <= stage3_data;
            rs <= stage3_rs;
            rw <= 1'b0;
            e <= stage3_e;
            busy <= stage3_busy || stage2_busy || stage1_busy;
        end
    end
    
    always @(*) begin
        ready = !stage2_busy && !stage3_busy && (stage1_state == IDLE);
    end
    
endmodule