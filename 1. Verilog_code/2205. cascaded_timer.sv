module cascaded_timer (
    input wire clk_i,
    input wire rst_n_i,
    input wire enable_i,
    input wire [7:0] timer1_max_i,
    input wire [7:0] timer2_max_i,
    output wire timer1_tick_o,
    output wire timer2_tick_o
);
    reg [7:0] timer1_count;
    reg [7:0] timer2_count;
    reg timer1_tick_r;
    reg timer2_tick_r;
    
    assign timer1_tick_o = timer1_tick_r;
    assign timer2_tick_o = timer2_tick_r;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            timer1_count <= 8'd0;
            timer1_tick_r <= 1'b0;
        end else if (enable_i) begin
            if (timer1_count >= timer1_max_i - 1) begin
                timer1_count <= 8'd0;
                timer1_tick_r <= 1'b1;
            end else begin
                timer1_count <= timer1_count + 1'b1;
                timer1_tick_r <= 1'b0;
            end
        end
    end
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            timer2_count <= 8'd0;
            timer2_tick_r <= 1'b0;
        end else if (timer1_tick_r) begin
            if (timer2_count >= timer2_max_i - 1) begin
                timer2_count <= 8'd0;
                timer2_tick_r <= 1'b1;
            end else begin
                timer2_count <= timer2_count + 1'b1;
                timer2_tick_r <= 1'b0;
            end
        end else begin
            timer2_tick_r <= 1'b0;
        end
    end
endmodule