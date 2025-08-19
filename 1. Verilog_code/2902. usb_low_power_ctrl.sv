module usb_low_power_ctrl(
    input clk_48mhz,
    input reset_n,
    input bus_activity,
    input suspend_req,
    input resume_req,
    output reg suspend_state,
    output reg clk_en,
    output reg pll_en
);
    localparam ACTIVE = 2'b00, IDLE = 2'b01, SUSPEND = 2'b10, RESUME = 2'b11;
    reg [1:0] state;
    reg [15:0] idle_counter;
    
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            state <= ACTIVE;
            idle_counter <= 16'd0;
            suspend_state <= 1'b0;
            clk_en <= 1'b1;
            pll_en <= 1'b1;
        end else begin
            case (state)
                ACTIVE: begin
                    clk_en <= 1'b1;
                    pll_en <= 1'b1;
                    if (bus_activity)
                        idle_counter <= 16'd0;
                    else begin
                        idle_counter <= idle_counter + 1'b1;
                        if (idle_counter > 16'd3000 || suspend_req)
                            state <= IDLE;
                    end
                end
                IDLE: begin
                    if (bus_activity) begin
                        state <= ACTIVE;
                        idle_counter <= 16'd0;
                    end else if (idle_counter > 16'd20000) begin
                        state <= SUSPEND;
                        suspend_state <= 1'b1;
                        clk_en <= 1'b0;
                        pll_en <= 1'b0;
                    end else
                        idle_counter <= idle_counter + 1'b1;
                end
                SUSPEND: begin
                    if (bus_activity || resume_req) begin
                        state <= RESUME;
                        pll_en <= 1'b1;
                    end
                end
                RESUME: begin
                    if (idle_counter < 16'd1000)
                        idle_counter <= idle_counter + 1'b1;
                    else begin
                        clk_en <= 1'b1;
                        state <= ACTIVE;
                        suspend_state <= 1'b0;
                        idle_counter <= 16'd0;
                    end
                end
            endcase
        end
    end
endmodule