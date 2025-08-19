//SystemVerilog - IEEE 1364-2005
module quad_encoder_timer (
    // Clock and Reset
    input wire clk,
    input wire rst,
    
    // Quadrature Encoder Inputs
    input wire quad_a,
    input wire quad_b,
    input wire timer_en,
    
    // AXI-Stream Output Interface
    output reg [31:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast,
    input wire m_axis_tready
);
    // Position and timer registers
    reg [15:0] position;
    reg [31:0] timer;
    
    // Stage 1: Input sampling
    reg quad_a_stage1, quad_b_stage1, timer_en_stage1;
    reg a_prev, b_prev;
    
    // Stage 2: Signal processing
    reg quad_a_stage2, quad_b_stage2, a_prev_stage2, b_prev_stage2, timer_en_stage2;
    reg count_up_stage2, count_down_stage2;
    reg edge_detected_stage2;
    
    // Stage 3: Computation
    reg [15:0] position_stage3;
    reg [31:0] timer_stage3;
    
    // Pipeline valid signals and output control
    reg valid_stage1, valid_stage2, valid_stage3;
    reg output_ready;
    
    // Stage 1: Input sampling
    always @(posedge clk) begin
        if (rst) begin
            quad_a_stage1 <= 1'b0;
            quad_b_stage1 <= 1'b0;
            timer_en_stage1 <= 1'b0;
            a_prev <= 1'b0;
            b_prev <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            quad_a_stage1 <= quad_a;
            quad_b_stage1 <= quad_b;
            timer_en_stage1 <= timer_en;
            a_prev <= quad_a;
            b_prev <= quad_b;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Signal processing
    always @(posedge clk) begin
        if (rst) begin
            quad_a_stage2 <= 1'b0;
            quad_b_stage2 <= 1'b0;
            a_prev_stage2 <= 1'b0;
            b_prev_stage2 <= 1'b0;
            timer_en_stage2 <= 1'b0;
            count_up_stage2 <= 1'b0;
            count_down_stage2 <= 1'b0;
            edge_detected_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            quad_a_stage2 <= quad_a_stage1;
            quad_b_stage2 <= quad_b_stage1;
            a_prev_stage2 <= a_prev;
            b_prev_stage2 <= b_prev;
            timer_en_stage2 <= timer_en_stage1;
            count_up_stage2 <= quad_a_stage1 ^ b_prev;
            count_down_stage2 <= quad_b_stage1 ^ a_prev;
            edge_detected_stage2 <= (quad_a_stage1 != a_prev) || (quad_b_stage1 != b_prev);
            valid_stage2 <= valid_stage1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Computation
    always @(posedge clk) begin
        if (rst) begin
            position_stage3 <= 16'h0000;
            timer_stage3 <= 32'h0;
            valid_stage3 <= 1'b0;
        end
        else if (valid_stage2) begin
            // Position computation
            if (edge_detected_stage2) begin
                if (count_up_stage2)
                    position_stage3 <= position + 1'b1;
                else if (count_down_stage2)
                    position_stage3 <= position - 1'b1;
                else
                    position_stage3 <= position;
            end
            else begin
                position_stage3 <= position;
            end
            
            // Timer computation
            if (timer_en_stage2)
                timer_stage3 <= timer + 32'h1;
            else
                timer_stage3 <= timer;
                
            valid_stage3 <= valid_stage2;
        end
        else begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // Internal registers update
    always @(posedge clk) begin
        if (rst) begin
            position <= 16'h0000;
            timer <= 32'h0;
            output_ready <= 1'b0;
        end
        else if (valid_stage3) begin
            position <= position_stage3;
            timer <= timer_stage3;
            output_ready <= 1'b1;
        end
        else if (m_axis_tvalid && m_axis_tready) begin
            output_ready <= 1'b0;
        end
    end
    
    // AXI-Stream output interface handling
    always @(posedge clk) begin
        if (rst) begin
            m_axis_tdata <= 32'h0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end
        else if (output_ready && (!m_axis_tvalid || m_axis_tready)) begin
            // Pack position and high 16 bits of timer into tdata
            m_axis_tdata <= {timer[15:0], position};
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= 1'b0;  // Not last word in sequence
        end
        else if (m_axis_tvalid && m_axis_tready) begin
            if (m_axis_tlast) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
            else begin
                // Send the second part (high bits of timer)
                m_axis_tdata <= {16'h0, timer[31:16]};
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1;  // Last word in sequence
            end
        end
    end
    
endmodule