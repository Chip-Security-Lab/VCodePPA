module triggered_timer #(parameter CNT_W = 32)(
    input wire clock, n_reset, trigger,
    input wire [CNT_W-1:0] target,
    output reg [CNT_W-1:0] counter,
    output reg complete
);
    localparam IDLE = 1'b0, COUNTING = 1'b1;
    reg state;
    reg trig_d1, trig_d2;
    wire trig_rising;
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin trig_d1 <= 1'b0; trig_d2 <= 1'b0; end
        else begin trig_d1 <= trigger; trig_d2 <= trig_d1; end
    end
    assign trig_rising = trig_d1 & ~trig_d2;
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state <= IDLE; counter <= {CNT_W{1'b0}}; complete <= 1'b0;
        end else case (state)
            IDLE: begin
                complete <= 1'b0;
                if (trig_rising) begin state <= COUNTING; counter <= {CNT_W{1'b0}}; end
            end
            COUNTING: begin
                counter <= counter + 1'b1;
                if (counter == target - 1) begin state <= IDLE; complete <= 1'b1; end
            end
        endcase
    end
endmodule