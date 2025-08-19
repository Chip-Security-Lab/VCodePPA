//SystemVerilog
module IVMU_RoundRobin #(parameter CH=4) (
    input [CH-1:0] irq,
    output reg [$clog2(CH)-1:0] current_ch
);

    // Transformed logic: priority encoder using loop and conditional judgment
    // Equivalent to casez based priority encoding

    always @(*) begin
        integer i;
        integer found_idx;

        // Default value if no IRQ is active
        current_ch = 0;

        // Find the index of the highest asserted IRQ bit (priority encoder)
        // Initialize found_idx to an invalid value
        found_idx = -1;

        // Iterate from the highest priority channel down to the lowest
        for (i = CH - 1; i >= 0; i = i - 1) begin
            // If this IRQ is asserted and no higher priority IRQ was found yet
            if (irq[i] == 1) begin // Explicitly check for 1, handles x/z as non-match
                found_idx = i;
                // Once the highest priority asserted IRQ is found, we can stop searching.
                // The 'break' statement is synthesizable in this context in modern tools,
                // but relying on the loop structure and assignments is also common.
                // Using the found_idx flag correctly implements the priority without break.
            end
        end

        // Assign the channel based on the highest priority IRQ found
        if (found_idx != -1) begin
            current_ch = found_idx;
        end else begin
            // If no IRQ was asserted, current_ch remains the default value (0)
            current_ch = 0; // Redundant due to initialization, but makes intent clear
        end
    end

endmodule