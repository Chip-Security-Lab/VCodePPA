//SystemVerilog
module eth_ifg_controller #(parameter IFG_BYTES = 12) (
    input wire clk,
    input wire rst_n,
    input wire tx_request,
    input wire tx_done,
    output reg tx_enable,
    output reg ifg_active
);
    // Counter and optimization variables
    reg [$clog2(IFG_BYTES):0] ifg_counter;
    
    // Pre-registered inputs
    reg tx_request_pre;
    reg tx_done_pre;
    
    // Optimized pipeline with forward retiming
    wire tx_done_edge;
    wire ifg_complete;
    wire grant_tx;
    
    // First stage - capture inputs directly without additional registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_request_pre <= 1'b0;
            tx_done_pre <= 1'b0;
        end else begin
            tx_request_pre <= tx_request;
            tx_done_pre <= tx_done;
        end
    end
    
    // Edge detection pushed after combinational logic
    reg tx_done_pre_delayed;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_done_pre_delayed <= 1'b0;
        end else begin
            tx_done_pre_delayed <= tx_done_pre;
        end
    end
    
    // Optimized combinational logic
    assign tx_done_edge = tx_done_pre && !tx_done_pre_delayed;
    assign ifg_complete = (ifg_counter == 0);
    assign grant_tx = tx_request_pre && !tx_enable && !ifg_active;
    
    // Merged IFG counter and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ifg_counter <= {$clog2(IFG_BYTES)+1{1'b0}};
            ifg_active <= 1'b0;
            tx_enable <= 1'b0;
        end else begin
            // IFG counter logic with forward retiming
            if (tx_done_edge) begin
                // Start IFG period immediately when tx_done edge detected
                ifg_counter <= IFG_BYTES;
                ifg_active <= 1'b1;
                tx_enable <= 1'b0;
            end else if (ifg_active && !ifg_complete) begin
                // Decrement counter during active IFG period
                ifg_counter <= ifg_counter - 1'b1;
            end else if (ifg_active && ifg_complete) begin
                // IFG period complete
                ifg_active <= 1'b0;
            end
            
            // Transmit enable logic with forward retiming
            if (!ifg_active || ifg_complete) begin
                if (grant_tx) begin
                    tx_enable <= 1'b1;
                end else if (!tx_request_pre) begin
                    tx_enable <= 1'b0;
                end
            end
        end
    end
endmodule