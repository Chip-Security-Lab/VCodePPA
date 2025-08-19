module cam_3_axi (
    input wire clk,
    input wire rst,
    
    // AXI-Stream Slave Interface (Input)
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    
    // AXI-Stream Master Interface (Output)
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    input wire m_axis_tready
);
    // Internal signals
    reg [7:0] stored_data;
    wire match;
    reg match_valid;
    reg s_tlast_reg;
    
    // AXI-Stream handshaking logic
    reg ready_to_receive;
    assign s_axis_tready = ready_to_receive;
    
    // Master interface signals
    assign m_axis_tdata = {7'b0, match}; // Match result in LSB
    assign m_axis_tvalid = match_valid;
    assign m_axis_tlast = s_tlast_reg;
    
    // Instantiate comparator
    comparator_3_axi comp (
        .a(stored_data),
        .b(s_axis_tdata),
        .match(match)
    );
    
    // Reset logic
    always @(posedge clk) begin
        if (rst) begin
            stored_data <= 8'b0;
            match_valid <= 1'b0;
            ready_to_receive <= 1'b1;
            s_tlast_reg <= 1'b0;
        end
    end
    
    // Input data handling
    always @(posedge clk) begin
        if (!rst) begin
            if (s_axis_tvalid && ready_to_receive) begin
                stored_data <= s_axis_tdata;
                s_tlast_reg <= s_axis_tlast;
            end
        end
    end
    
    // Match valid control
    always @(posedge clk) begin
        if (!rst) begin
            if (s_axis_tvalid && ready_to_receive) begin
                match_valid <= 1'b1;
            end else if (match_valid && m_axis_tready) begin
                match_valid <= 1'b0;
            end
        end
    end
    
    // Ready to receive control
    always @(posedge clk) begin
        if (!rst) begin
            if (s_axis_tvalid && ready_to_receive) begin
                ready_to_receive <= 1'b0;
            end else if (match_valid && m_axis_tready) begin
                ready_to_receive <= 1'b1;
            end else if (!match_valid && !ready_to_receive) begin
                ready_to_receive <= 1'b1;
            end
        end
    end
endmodule

module comparator_3_axi (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire match
);
    // Optimized for better timing
    assign match = (a == b);
endmodule